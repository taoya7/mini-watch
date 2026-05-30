.PHONY: prepare fmt lint build update publish-check

BIN := target/release/macmon
INSTALL_BIN ?= /opt/homebrew/bin/macmon

prepare: fmt lint build

lint:
	cargo fmt --check
	cargo clippy --all-targets --all-features -- -D warnings
	cargo check --release --locked

fmt:
	cargo fmt

build:
	cargo build --release
	install -m 0755 $(BIN) $(INSTALL_BIN)
	ls -lh $(BIN) $(INSTALL_BIN)

update:
	@# cargo install cargo-edit
	cargo upgrade -i

publish-check:
	cargo package --list --allow-dirty
	cargo publish --dry-run --allow-dirty
