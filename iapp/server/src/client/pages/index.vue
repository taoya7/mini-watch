<script setup lang="ts">
import BaseInfoCard from '@client/components/dashboard/base-info-card.vue'
import ConnectionCard from '@client/components/dashboard/connection-card.vue'
import ConsoleCard from '@client/components/dashboard/console-card.vue'
import CurrentPageCard from '@client/components/dashboard/current-page-card.vue'
import MediaControlsCard from '@client/components/dashboard/media-controls-card.vue'
import PageSwitcherCard from '@client/components/dashboard/page-switcher-card.vue'
import ThemePickerCard from '@client/components/dashboard/theme-picker-card.vue'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@client/components/ui/tabs'
</script>

<template>
  <div class="min-h-screen bg-zinc-50 p-4">
    <div class="mx-auto max-w-6xl">
      <Tabs default-value="base">
        <!-- 顶部 Tabs 切换 -->
        <TabsList>
          <TabsTrigger value="base">
            基础信息
          </TabsTrigger>
          <TabsTrigger value="console">
            控制台
          </TabsTrigger>
        </TabsList>

        <!-- 基础信息 -->
        <TabsContent value="base" class="space-y-3">
          <!-- 第一行：3 个状态卡 -->
          <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <ConnectionCard />
            <CurrentPageCard />
            <PageSwitcherCard />
          </div>

          <!-- 第二行：主机信息 + 主题色（2:1 比例） -->
          <div class="grid grid-cols-1 gap-3 lg:grid-cols-3">
            <BaseInfoCard class="lg:col-span-2" />
            <ThemePickerCard />
          </div>

          <!-- 第三行：媒体控制（亮度 + 音量，纵向滑条同卡） -->
          <div class="sm:max-w-xs">
            <MediaControlsCard />
          </div>
        </TabsContent>

        <!-- 控制台 -->
        <TabsContent value="console">
          <ConsoleCard />
        </TabsContent>
      </Tabs>
    </div>
  </div>
</template>
