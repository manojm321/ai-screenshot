# Contributing to AI Screenshot

Thank you for your interest in contributing to AI Screenshot!

## Development & Building Locally

### Prerequisites
- macOS 14.0+ (macOS 15.1+ recommended for Apple Intelligence)
- Apple Silicon (M-series) Mac
- Xcode Command Line Tools (`xcode-select --install`)
- Apple Foundation Models CLI (`/usr/bin/fm`)

### Quickstart

1. **Clone the repository:**
   ```bash
   git clone https://github.com/manojm321/ai-screenshot.git
   cd ai-screenshot
   ```

2. **Build the `.app` bundle:**
   ```bash
   make app
   ```

3. **Verify the bundle and code signature:**
   ```bash
   make test
   ```

4. **Install locally:**
   ```bash
   make install
   ```

5. **Clean build artifacts:**
   ```bash
   make clean
   ```

## Guidelines

- **Keep It Native**: Maintain zero third-party dependencies. AI Screenshot relies solely on native macOS frameworks (`Cocoa`, `AppKit`, `Carbon`, `screencapture`, `fm`).
- **Privacy First**: Ensure screenshot data is never logged, transmitted over the network, or saved to unverified locations.
- **Code Style**: Format Swift files cleanly with standard Swift naming conventions and maintain comments where relevant.
- **Test Before Committing**: Run `make test` and manually test taking a screenshot and dragging the floating thumbnail before opening a pull request.
