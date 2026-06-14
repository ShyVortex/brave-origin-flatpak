# Brave Origin Flatpak

This repository contains the [Flatpak](https://flatpak.org/) manifest for **Brave Origin**, a minimalist, privacy-focused edition of the Brave web browser. Brave Origin is designed for users who want the core benefits of Brave (such as Brave Shields, tracker blocking, and Chromium security patches) without the optional integration of services like Brave Rewards, Wallet, Leo AI, and VPN.

It wraps the official prebuilt binaries for Origin from the [Brave Browser Linux project](https://github.com/brave/brave-browser) into a partially sandboxed Flatpak environment,
ensuring it runs consistently across different Linux distributions.

---

## Installation (Recommended)

The easiest way to install Brave Origin is using the standalone bundle. This bypasses the need for manual repositories and works on any system with Flatpak installed.

1.  **Download** the latest `.flatpak` bundle from the [**Releases Page**](https://github.com/ShyVortex/brave-origin-flatpak/releases).
2.  **Install** it via the command line, in the directory where you downloaded the file:

    ```bash
    flatpak install ./brave-origin-[VERSION]-[ARCH].flatpak
    ```

    *Note: on some distributions, you can simply double-click the downloaded file to install it via your Software Center.*

---

## Building from Source

If you want to build the package yourself or contribute to the manifest, follow these steps.

### Prerequisites
Ensure you have `flatpak` and `flatpak-builder` installed. You also need the Flathub repository enabled to download the Freedesktop SDK/Runtime (version 25.08).

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install org.freedesktop.Sdk/x86_64/25.08
```

### Build & Install
Run the following command in the root of this repository. This will download the binary, build the sandbox, and install it to your user directory.

For x86_64 systems:

```bash
flatpak-builder --arch=x86_64 --user --install --force-clean build-dir io.github.shyvortex.BraveOrigin.yaml
```

For ARM64 systems:

```bash
flatpak-builder --arch=aarch64 --user --install --force-clean build-dir io.github.shyvortex.BraveOrigin.yaml
```

*Note: to install for all users, use sudo and replace '--user' with '--system'.*

---

## Running the App

Once installed (via bundle or local build), you can launch Brave Origin from your application menu or via the terminal:

```bash
flatpak run io.github.shyvortex.BraveOrigin
```

---

## Uninstallation

To remove Brave Origin and its data:

```bash
flatpak uninstall io.github.shyvortex.BraveOrigin
# Optional: Remove app data
rm -rf ~/.var/app/io.github.shyvortex.BraveOrigin
```

---

**Disclaimer:** This is an unofficial packaging project. For issues related to the original non-origin package, please refer to the [upstream repository](https://github.com/flathub/com.brave.Browser). For issues strictly related to my Brave Origin package, feel free to open an issue here.
