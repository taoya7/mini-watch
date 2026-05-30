PROJECT     := iapp
SERVER      := $(PROJECT)/server
FLUTTER    ?= flutter
PNPM       ?= pnpm
PM2        ?= pm2
DIST        := dist
IPA_OUT     := $(PROJECT)/build/ios/ipa
APP_DIR     := $(PROJECT)/build/ios/iphoneos
SERVER_BIN  := $(SERVER)/dist/server-aarch64-apple-darwin

# 让子进程能找到 CocoaPods（pod 在 /opt/homebrew/bin）
export PATH := /opt/homebrew/bin:$(PATH)

.PHONY: ipa unsigned build-server deploy-server clean
.DEFAULT_GOAL := unsigned

# 已签名 ipa（需配开发证书/描述文件）
ipa:
	cd $(PROJECT) && $(FLUTTER) build ipa --export-method=development
	mkdir -p $(DIST)
	cp -f $(IPA_OUT)/*.ipa $(DIST)/

# 未签名 ipa：先出 .app，再手动打 Payload 包，自己签名
unsigned:
	cd $(PROJECT) && $(FLUTTER) build ios --release --no-codesign
	rm -rf $(APP_DIR)/Payload $(DIST)/app.ipa
	mkdir -p $(APP_DIR)/Payload $(DIST)
	cp -R $(APP_DIR)/Runner.app $(APP_DIR)/Payload/
	cd $(APP_DIR) && zip -qr Payload.ipa Payload
	mv -f $(APP_DIR)/Payload.ipa $(DIST)/app.ipa
	@echo "未签名 ipa -> $(DIST)/app.ipa"

# 打包后端二进制（macOS arm64） -> dist/
build-server:
	cd $(SERVER) && pnpm run build:binary:mac-arm
	mkdir -p $(DIST)
	mv -f $(SERVER_BIN) $(DIST)/
	@echo "后端二进制 -> $(DIST)/$(notdir $(SERVER_BIN))"

# 打包后端 JS（dist/bundle.cjs + front-dist）并用 pm2 启动/热重载（端口 4600）
deploy-server:
	cd $(SERVER) && $(PNPM) run bundle
	$(PM2) startOrReload ecosystem.config.cjs --update-env
	@echo "pm2 已启动 mini-watch-server (PORT=4600)"

clean:
	cd $(PROJECT) && $(FLUTTER) clean
