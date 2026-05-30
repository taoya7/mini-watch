use core_foundation::dictionary::CFDictionaryRef;
use serde::Serialize;

use crate::sources::{
  IOHIDSensors, IOReport, SMC, SocInfo, cfio_get_residencies, cfio_watts, libc_ram, libc_swap,
};

type WithError<T> = Result<T, Box<dyn std::error::Error>>;

// const CPU_FREQ_DICE_SUBG: &str = "CPU Complex Performance States";
const CPU_FREQ_CORE_SUBG: &str = "CPU Core Performance States";
const GPU_FREQ_DICE_SUBG: &str = "GPU Performance States";

// MARK: Structs

#[derive(Debug, Default, Serialize)]
pub struct TempMetrics {
  pub cpu_temp_avg: f32, // Celsius
  pub gpu_temp_avg: f32, // Celsius
}

#[derive(Debug, Default, Serialize)]
pub struct MemMetrics {
  pub ram_total: u64,  // bytes
  pub ram_usage: u64,  // bytes
  pub swap_total: u64, // bytes
  pub swap_usage: u64, // bytes
}

#[derive(Debug, Default, Clone, Serialize)]
pub struct FanMetrics {
  pub id: String,
  pub rpm: u32,
}

#[derive(Debug, Default, Serialize)]
pub struct Metrics {
  pub temp: TempMetrics,
  pub memory: MemMetrics,
  pub fans_number: u32,       // sum of fan speeds in RPM
  pub fans: Vec<FanMetrics>,  // RPM per fan
  pub ecpu_usage: (u32, f32), // freq, percent_from_max
  pub pcpu_usage: (u32, f32), // freq, percent_from_max
  pub cpu_usage_pct: f32,     // combined ecpu+pcpu usage, weighted by core count
  pub gpu_usage: (u32, f32),  // freq, percent_from_max
  pub cpu_power: f32,         // Watts
  pub gpu_power: f32,         // Watts
  pub ane_power: f32,         // Watts
  pub all_power: f32,         // Watts
  pub sys_power: f32,         // Watts
  pub ram_power: f32,         // Watts
  pub gpu_ram_power: f32,     // Watts
}

struct SmcSensors {
  smc: SMC,
  cpu_keys: Vec<String>,
  gpu_keys: Vec<String>,
  fan_keys: Vec<String>,
}

// MARK: Helpers

pub fn zero_div<T: core::ops::Div<Output = T> + Default + PartialEq>(a: T, b: T) -> T {
  let zero: T = Default::default();
  if b == zero { zero } else { a / b }
}

fn is_valid_temp(val: f32) -> bool {
  val > 0.0 && val <= 150.0
}

fn calc_freq(item: CFDictionaryRef, freqs: &[u32]) -> (u32, f32) {
  let items = cfio_get_residencies(item); // (ns, freq)
  let (len1, len2) = (items.len(), freqs.len());
  assert!(len1 > len2, "cacl_freq invalid data: {} vs {}", len1, len2); // todo?

  // IDLE / DOWN for CPU; OFF for GPU; DOWN only on M2?/M3 Max Chips
  let offset = items.iter().position(|x| x.0 != "IDLE" && x.0 != "DOWN" && x.0 != "OFF").unwrap();

  let usage = items.iter().map(|x| x.1 as f64).skip(offset).sum::<f64>();
  let total = items.iter().map(|x| x.1 as f64).sum::<f64>();
  let count = freqs.len();

  let mut avg_freq = 0f64;
  for i in 0..count {
    let percent = zero_div(items[i + offset].1 as _, usage);
    avg_freq += percent * freqs[i] as f64;
  }

  let usage_ratio = zero_div(usage, total);
  let min_freq = *freqs.first().unwrap() as f64;
  let max_freq = *freqs.last().unwrap() as f64;
  let from_max = (avg_freq.max(min_freq) * usage_ratio) / max_freq;

  (avg_freq as u32, from_max as f32)
}

fn calc_freq_final(items: &[(u32, f32)], freqs: &[u32]) -> (u32, f32) {
  let avg_freq = zero_div(items.iter().map(|x| x.0 as f32).sum(), items.len() as f32);
  let avg_perc = zero_div(items.iter().map(|x| x.1).sum(), items.len() as f32);
  let min_freq = *freqs.first().unwrap() as f32;

  (avg_freq.max(min_freq) as u32, avg_perc)
}

fn parse_smc_fan_rpm(unit: &str, data: &[u8]) -> Option<u32> {
  match unit {
    "fpe2" if data.len() >= 2 => {
      let raw = u16::from_be_bytes(data[0..2].try_into().ok()?);
      Some((raw >> 2) as u32)
    }
    "flt " if data.len() == 4 => {
      let rpm = f32::from_le_bytes(data.try_into().ok()?);
      (rpm.is_finite() && rpm >= 0.0).then_some(rpm.round() as u32)
    }
    _ => None,
  }
}

fn is_fan_actual_key(key: &str) -> bool {
  let bytes = key.as_bytes();
  bytes.len() == 4
    && bytes[0] == b'F'
    && bytes[1].is_ascii_digit()
    && bytes[2] == b'A'
    && bytes[3] == b'c'
}

fn init_smc() -> WithError<SmcSensors> {
  let mut smc = SMC::new()?;
  const FLOAT_TYPE: u32 = 1718383648; // FourCC: "flt "

  let mut cpu_sensors = Vec::new();
  let mut gpu_sensors = Vec::new();
  let mut fan_sensors = Vec::new();

  let names = smc.read_all_keys().unwrap_or(vec![]);
  for name in &names {
    if is_fan_actual_key(name) {
      fan_sensors.push(name.clone());
      continue;
    }

    let key = match smc.read_key_info(name) {
      Ok(key) => key,
      Err(_) => continue,
    };

    if key.data_size != 4 || key.data_type != FLOAT_TYPE {
      continue;
    }

    let _ = match smc.read_val(name) {
      Ok(val) => val,
      Err(_) => continue,
    };

    // Unfortunately, it is not known which keys are responsible for what.
    // Basically in the code that can be found publicly "Tp" is used for CPU and "Tg" for GPU.

    match name {
      // "Tp" – performance cores, "Te" – efficiency cores, "Ts" – super cores (M5+)
      name if name.starts_with("Tp") || name.starts_with("Te") || name.starts_with("Ts") => {
        cpu_sensors.push(name.clone())
      }
      name if name.starts_with("Tg") => gpu_sensors.push(name.clone()),
      _ => (),
    }
  }

  fan_sensors.sort();

  // println!("{} {}", cpu_sensors.len(), gpu_sensors.len());
  Ok(SmcSensors { smc, cpu_keys: cpu_sensors, gpu_keys: gpu_sensors, fan_keys: fan_sensors })
}

// MARK: Sampler

pub struct Sampler {
  soc: SocInfo,
  ior: IOReport,
  hid: IOHIDSensors,
  smc: SMC,
  smc_cpu_keys: Vec<String>,
  smc_gpu_keys: Vec<String>,
  smc_fan_keys: Vec<String>,
}

impl Sampler {
  pub fn new() -> WithError<Self> {
    let channels = vec![
      ("Energy Model", None), // cpu/gpu/ane power
      // ("CPU Stats", Some(CPU_FREQ_DICE_SUBG)), // cpu freq by cluster
      ("CPU Stats", Some(CPU_FREQ_CORE_SUBG)), // cpu freq per core
      ("GPU Stats", Some(GPU_FREQ_DICE_SUBG)), // gpu freq
    ];

    let soc = SocInfo::new()?;
    let ior = IOReport::new(channels)?;
    let hid = IOHIDSensors::new()?;
    let SmcSensors { smc, cpu_keys: smc_cpu_keys, gpu_keys: smc_gpu_keys, fan_keys: smc_fan_keys } =
      init_smc()?;

    Ok(Sampler { soc, ior, hid, smc, smc_cpu_keys, smc_gpu_keys, smc_fan_keys })
  }

  fn get_temp_smc(&mut self) -> WithError<TempMetrics> {
    let mut cpu_metrics = Vec::new();
    for sensor in &self.smc_cpu_keys {
      let val = self.smc.read_val(sensor)?;
      let val = f32::from_le_bytes(val.data[0..4].try_into().unwrap());
      if is_valid_temp(val) {
        cpu_metrics.push(val);
      }
    }

    let mut gpu_metrics = Vec::new();
    for sensor in &self.smc_gpu_keys {
      let val = self.smc.read_val(sensor)?;
      let val = f32::from_le_bytes(val.data[0..4].try_into().unwrap());
      if is_valid_temp(val) {
        gpu_metrics.push(val);
      }
    }

    let cpu_temp_avg = zero_div(cpu_metrics.iter().sum::<f32>(), cpu_metrics.len() as f32);
    let gpu_temp_avg = zero_div(gpu_metrics.iter().sum::<f32>(), gpu_metrics.len() as f32);

    Ok(TempMetrics { cpu_temp_avg, gpu_temp_avg })
  }

  fn get_temp_hid(&mut self) -> WithError<TempMetrics> {
    let metrics = self.hid.get_metrics();

    let mut cpu_values = Vec::new();
    let mut gpu_values = Vec::new();

    for (name, value) in &metrics {
      if name.starts_with("pACC MTR Temp Sensor") || name.starts_with("eACC MTR Temp Sensor") {
        // println!("{}: {}", name, value);
        if is_valid_temp(*value) {
          cpu_values.push(*value);
        }
        continue;
      }

      if name.starts_with("GPU MTR Temp Sensor") {
        // println!("{}: {}", name, value);
        if is_valid_temp(*value) {
          gpu_values.push(*value);
        }
        continue;
      }
    }

    let cpu_temp_avg = zero_div(cpu_values.iter().sum(), cpu_values.len() as f32);
    let gpu_temp_avg = zero_div(gpu_values.iter().sum(), gpu_values.len() as f32);

    Ok(TempMetrics { cpu_temp_avg, gpu_temp_avg })
  }

  fn get_temp(&mut self) -> WithError<TempMetrics> {
    // HID for M1, SMC for M2/M3
    // UPD: Looks like HID/SMC related to OS version, not to the chip (SMC available from macOS 14)
    match !self.smc_cpu_keys.is_empty() {
      true => self.get_temp_smc(),
      false => self.get_temp_hid(),
    }
  }

  fn get_mem(&mut self) -> WithError<MemMetrics> {
    let (ram_usage, ram_total) = libc_ram()?;
    let (swap_usage, swap_total) = libc_swap()?;
    Ok(MemMetrics { ram_total, ram_usage, swap_total, swap_usage })
  }

  fn get_sys_power(&mut self) -> WithError<f32> {
    let val = self.smc.read_val("PSTR")?;
    let val = f32::from_le_bytes(val.data.clone().try_into().unwrap());
    Ok(val)
  }

  fn get_fans(&mut self) -> Vec<FanMetrics> {
    let mut fans = Vec::new();
    for key in &self.smc_fan_keys {
      let Ok(val) = self.smc.read_val(key) else { continue };
      let Some(rpm) = parse_smc_fan_rpm(&val.unit, &val.data) else { continue };
      let id = (key.as_bytes()[1] as char).to_string();
      fans.push(FanMetrics { id, rpm });
    }

    fans
  }

  pub fn get_metrics(&mut self, duration: u32) -> WithError<Metrics> {
    let measures: usize = 4;
    let mut results: Vec<Metrics> = Vec::with_capacity(measures);

    // CPU Stats channel naming by chip family (see: https://github.com/vladkens/macmon/issues/47)
    //   M1-M4:  ECPU* = efficiency cores (lower tier)
    //           PCPU* = performance cores (top tier)
    //   M5:     Apple renamed ECPU → MCPU in IOReport and introduced a third core tier.
    //           Three-tier architecture (sysctl hw.perflevel{N}.name):
    //             perflevel0 = Super       (top tier,    ex-P, PCPU* in IOReport)
    //             perflevel1 = Performance (mid tier,    Pro/Max only, MCPU* in IOReport)
    //             perflevel2 = Efficiency  (base M5 only, absent on Pro/Max)
    //           M5 Max example: 6 Super + 12 Performance + 0 Efficiency = 18 total.
    //   Ultra:  Any-generation Ultra chips prefix channels with "DIE_N_"
    //           (e.g. "DIE_0_ECPU0"), so use contains() not starts_with() — same
    //           pattern as Energy Model's "DIE_{}_CPU Energy".

    // do several samples to smooth metrics
    // see: https://github.com/vladkens/macmon/issues/10
    for (sample, dt) in self.ior.get_samples(duration as u64, measures) {
      let mut ecpu_usages = Vec::new();
      let mut pcpu_usages = Vec::new();
      let mut rs = Metrics::default();

      for x in sample {
        if x.group == "CPU Stats" && x.subgroup == CPU_FREQ_CORE_SUBG {
          if x.channel.contains("PCPU") {
            pcpu_usages.push(calc_freq(x.item, &self.soc.pcpu_freqs));
            continue;
          }

          if x.channel.contains("ECPU") || x.channel.contains("MCPU") {
            ecpu_usages.push(calc_freq(x.item, &self.soc.ecpu_freqs));
            continue;
          }
        }

        if x.group == "GPU Stats" && x.subgroup == GPU_FREQ_DICE_SUBG {
          match x.channel.as_str() {
            "GPUPH" => rs.gpu_usage = calc_freq(x.item, &self.soc.gpu_freqs[1..]),
            _ => {}
          }
        }

        if x.group == "Energy Model" {
          match x.channel.as_str() {
            "GPU Energy" => rs.gpu_power += cfio_watts(x.item, &x.unit, dt)?,
            // "CPU Energy" for Basic / Max, "DIE_{}_CPU Energy" for Ultra
            c if c.ends_with("CPU Energy") => rs.cpu_power += cfio_watts(x.item, &x.unit, dt)?,
            // same pattern next keys: "ANE" for Basic, "ANE0" for Max, "ANE0_{}" for Ultra
            c if c.starts_with("ANE") => rs.ane_power += cfio_watts(x.item, &x.unit, dt)?,
            c if c.starts_with("DRAM") => rs.ram_power += cfio_watts(x.item, &x.unit, dt)?,
            c if c.starts_with("GPU SRAM") => rs.gpu_ram_power += cfio_watts(x.item, &x.unit, dt)?,
            _ => {}
          }
        }
      }

      // Filter dead/disabled cores (e.g. M5 Max MCPU0 cluster is all-DOWN)
      ecpu_usages.retain(|&(_, pct)| pct > 0.0);
      rs.ecpu_usage = calc_freq_final(&ecpu_usages, &self.soc.ecpu_freqs);
      rs.pcpu_usage = calc_freq_final(&pcpu_usages, &self.soc.pcpu_freqs);
      results.push(rs);
    }

    let ecores = self.soc.ecpu_cores as f32;
    let pcores = self.soc.pcpu_cores as f32;
    let tcores = ecores + pcores;

    let mut rs = Metrics::default();
    rs.ecpu_usage.0 = zero_div(results.iter().map(|x| x.ecpu_usage.0).sum(), measures as _);
    rs.ecpu_usage.1 = zero_div(results.iter().map(|x| x.ecpu_usage.1).sum(), measures as _);
    rs.pcpu_usage.0 = zero_div(results.iter().map(|x| x.pcpu_usage.0).sum(), measures as _);
    rs.pcpu_usage.1 = zero_div(results.iter().map(|x| x.pcpu_usage.1).sum(), measures as _);
    rs.cpu_usage_pct = zero_div(rs.ecpu_usage.1 * ecores + rs.pcpu_usage.1 * pcores, tcores);
    rs.gpu_usage.0 = zero_div(results.iter().map(|x| x.gpu_usage.0).sum(), measures as _);
    rs.gpu_usage.1 = zero_div(results.iter().map(|x| x.gpu_usage.1).sum(), measures as _);
    rs.cpu_power = zero_div(results.iter().map(|x| x.cpu_power).sum(), measures as _);
    rs.gpu_power = zero_div(results.iter().map(|x| x.gpu_power).sum(), measures as _);
    rs.ane_power = zero_div(results.iter().map(|x| x.ane_power).sum(), measures as _);
    rs.ram_power = zero_div(results.iter().map(|x| x.ram_power).sum(), measures as _);
    rs.gpu_ram_power = zero_div(results.iter().map(|x| x.gpu_ram_power).sum(), measures as _);
    rs.all_power = rs.cpu_power + rs.gpu_power + rs.ane_power;

    rs.memory = self.get_mem()?;
    rs.temp = self.get_temp()?;
    rs.fans = self.get_fans();
    rs.fans_number = rs.fans.iter().map(|fan| fan.rpm).sum();

    rs.sys_power = match self.get_sys_power() {
      Ok(val) => val.max(rs.all_power),
      Err(_) => 0.0,
    };

    Ok(rs)
  }

  /// Getter for the `soc` field
  pub fn get_soc_info(&self) -> &SocInfo {
    &self.soc
  }
}

#[cfg(test)]
mod tests {
  use super::{is_fan_actual_key, parse_smc_fan_rpm};

  #[test]
  fn ultra_cpu_channel_matching() {
    // On Ultra chips (M1/M2/M3 Ultra) IOReport CPU Stats channels are prefixed "DIE_N_".
    // These should be recognised; they were with contains() in v0.6.1 but broke when
    // ff5f058 changed to starts_with().
    let cases = [
      ("DIE_0_ECPU0", "ecpu"),
      ("DIE_1_ECPU0", "ecpu"),
      ("DIE_0_PCPU0", "pcpu"),
      ("DIE_1_PCPU0", "pcpu"),
      // Standard (non-Ultra) channels must still work
      ("ECPU0", "ecpu"),
      ("PCPU0", "pcpu"),
      ("MCPU0", "ecpu"), // M5+ performance cores map to ecpu slot
    ];
    for (ch, expected) in cases {
      let matched = if ch.contains("PCPU") {
        "pcpu"
      } else if ch.contains("ECPU") || ch.contains("MCPU") {
        "ecpu"
      } else {
        "none"
      };
      assert_eq!(matched, expected, "channel {ch}");
    }
  }

  #[test]
  fn parse_smc_fan_speed_rpm() {
    assert_eq!(parse_smc_fan_rpm("fpe2", &[0x21, 0xc0]), Some(2160));
    assert_eq!(parse_smc_fan_rpm("flt ", &2160f32.to_le_bytes()), Some(2160));
    assert_eq!(parse_smc_fan_rpm("ui16", &[0x08, 0x70]), None);
  }

  #[test]
  fn detect_smc_fan_actual_keys() {
    assert!(is_fan_actual_key("F0Ac"));
    assert!(is_fan_actual_key("F1Ac"));
    assert!(!is_fan_actual_key("F0Mn"));
    assert!(!is_fan_actual_key("FNum"));
    assert!(!is_fan_actual_key("TC0P"));
  }
}
