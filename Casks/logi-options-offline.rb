cask "logi-options-offline" do
  version "1.96.781095"
  sha256 "fb6a3f87be76131b5a4cefc97cc978381cc6080949540c4455643130b6d53864"

  url "https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer_offline.zip"
  name "Logi Options Offline"
  desc "Offline software for Logitech devices"
  homepage "https://prosupport.logi.com/hc/en-us/articles/10991109278871-Logitech-Options-Offline-Installer"

  livecheck do
    skip "Offline version"
  end

  auto_updates true
  depends_on macos: ">= :catalina"

  installer script: {
    executable: "logioptionsplus_installer_offline.app/Contents/MacOS/logioptionsplus_installer",
    args: ["--quiet"],
    sudo: true,
  }

  uninstall launchctl: [
             "com.logi.cp-dev-mgr",
             "com.logi.optionsplus",
             "com.logi.optionsplus.updater",
           ],
           quit: [
             "com.logi.cp-dev-mgr",
             "com.logi.optionsplus",
             "com.logi.optionsplus.driverhost",
             "com.logi.optionsplus.updater",
             "com.logitech.FirmwareUpdateTool",
             "com.logitech.logiaipromptbuilder",
           ],
           delete: [
             "/Applications/logioptionsplus.app",
             "/Applications/Utilities/Logi Options+ Driver Installer.bundle",
             "/Library/Application Support/Logitech.localized/LogiOptionsPlus",
           ],
           rmdir: "/Library/Application Support/Logitech.localized"

  zap trash: [
    "/Users/Shared/logi",
    "/Users/Shared/LogiOptionsPlus",
    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.logi.optionsplus*.sfl*",
    "~/Library/Application Support/LogiOptionsPlus",
    "~/Library/Preferences/com.logi.cp-dev-mgr.plist",
    "~/Library/Preferences/com.logi.optionsplus.driverhost.plist",
    "~/Library/Preferences/com.logi.optionsplus.plist",
    "~/Library/Saved Application State/com.logi.optionsplus.savedState",
  ]

  caveats do
    reboot
  end
end
