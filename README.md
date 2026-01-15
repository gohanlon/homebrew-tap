# homebrew-tap

```
brew uninstall --zap --cask logi-options+  # if cask previously installed
brew tap gohanlon/tap
brew install --cask offline-logi-options+

# to update
brew update && brew reinstall --cask offline-logi-options+
```

## Casks

**offline-logi-options+** — Logitech's [offline Options+ installer](https://prosupport.logi.com/hc/en-us/articles/10991109278871-Logitech-Options-Offline-Installer). Per Logitech, it doesn't send analytics and cloud features are disabled. Note: the offline version was [still affected](https://support.logi.com/hc/en-us/articles/37493733117847-Options-and-G-HUB-macOS-Certificate-Issue) by the January 2026 certificate incident.

## Maintenance

A daily workflow checks for upstream changes and opens a PR when updates are available.

## Acknowledgments

Based on work by [eternal-dissident](https://github.com/eternal-dissident/homebrew-tap).
