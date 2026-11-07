# 📸 AI Screenshot Renamer (`AI Screenshot.app`)

[![Build macOS App](https://github.com/manojm321/ai-screenshot/actions/workflows/build.yml/badge.svg)](https://github.com/manojm321/ai-screenshot/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS 14+](https://img.shields.io/badge/Platform-macOS%2014%2B%20(Apple%20Silicon)-black.svg)](https://apple.com/macos)

An open-source macOS utility that replaces standard screenshot naming with **AI-generated semantic descriptions + timestamps** using macOS's native on-device **Apple Foundation Models (`fm`) CLI**.

No API keys. No external servers. 100% on-device, private, and automated.

---

## ✨ Features

- **On-Device Vision AI**: Uses macOS's native `fm respond --image` command to analyze screenshot content locally in ~1 second.
- **Strict, Clean Naming**:
  ```text
  YYYY-MM-DD_HHMMSS_<slug>.png
  ```
  - *Example*: `2026-11-07_104215_payment-details-list.png`
  - Sanitized strictly to alphanumeric characters (`a-z`, `A-Z`, `0-9`), hyphens (`-`), and underscores (`_`).
- **Native Floating Thumbnail**:
  - Displays a floating preview in the bottom-right corner for 4.5 seconds (just like macOS default).
  - **Click**: Opens screenshot in **Preview**.
  - **Right-Click**: Reveals screenshot in **Finder**.
  - **Drag & Drop**: Drag directly into Slack, Discord, Mail, or a web browser.
- **Interactive Capture**: Uses native `screencapture -i` for pixel-accurate crosshairs or window capture (`Space`).
- **Native Global Hotkey**: Registers **`⌘ + ⇧ + 1`** via macOS's native Carbon HotKey API (`RegisterEventHotKey`) with 0ms latency and no Accessibility permissions needed.
- **Menu Bar Companion**: Sleek camera status item in the menu bar with one-click capture, quick access to your screenshot directory, and Launch at Login toggle.
- **GitHub Actions CI**: Automated building and zip artifact generation on every commit and release.

---

## 🚀 Installation

### Option 1: One-Command Local Build & Install

```bash
git clone https://github.com/manojm321/ai-screenshot.git
cd ai-screenshot
./install.sh
```

This compiles `AI Screenshot.app`, installs it to `/Applications`, launches the background agent, and enables **`⌘ + ⇧ + 1`** immediately.

### Option 2: Download Prebuilt from GitHub Releases / CI

1. Download `AI-Screenshot.zip` from the latest [GitHub Release](https://github.com/manojm321/ai-screenshot/releases) or CI build artifact.
2. Unzip and drag `AI Screenshot.app` into your `/Applications` folder.
3. Launch `AI Screenshot.app`. It will appear in your top menu bar and listen for **`⌘ + ⇧ + 1`**.

---

## ⌨️ How the Shortcut Works

1. **Native HotKey (`RegisterEventHotKey`)**: The app directly registers `⌘ + ⇧ + 1` with the macOS window server.
2. **Instant Response**: Handled directly in-process with 0ms latency.
3. **Launch at Login**: Click the camera icon in your top menu bar and check **Launch at Login** to keep `⌘ + ⇧ + 1` active across system restarts.

To uninstall anytime:
```bash
make uninstall
```

---

## 🛠 Architecture

```mermaid
flowchart LR
    A["Cmd + Shift + 1"] --> B["AI Screenshot.app\n(Native Carbon HotKey)"]
    B --> C["screencapture -i\n(Native macOS Crosshair)"]
    C -->|Area Selected| D["fm respond --image\n(Apple Foundation Model CLI)"]
    D --> E["Slug Sanitizer\n(regex whitelist: a-z0-9_-)"]
    E --> F["Save to ~/Desktop/\nYYYY-MM-DD_HHMMSS_slug.png"]
    F --> G["Native Floating Thumbnail\n(NSPanel Preview)"]
    G -->|Drag & Drop| H["Slack / Mail / Browser"]
    G -->|Click| I["Open in Preview"]
```

---

## 📄 License

[MIT](LICENSE)
