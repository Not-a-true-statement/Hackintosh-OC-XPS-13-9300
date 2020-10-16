# Hackintosh OpenCore XPS 13 9300
Use this guide on your own risk.

# Configuration
## Hardware
| Hardware | Specs |
| ------------- | ------------- |
| **CPU** | i7-1065G7 |
| **Graphics** | Intel(R) Iris(R) Plus Graphics |
| **Display** | UHD+ (3840x2400px touchscreen) |
| **RAM** | 16GB 3733MHz LPDDR4x|
| **SSD** | 1TB M.2 PCIe NVMe Solid State Drive |
| **Wi-Fi/BT** | Killer AX1650 (intel Wifi 6) |
| **Webcam** | |
| **Fingerprint reader** ||
| **Windows Hello** | |
| **SD Reader** ||

# What works and what doesn't

| Feature | Status | Notes |
| ------------- | ------------- | ------------- |
| **Intel iGPU** | ✅ Working ||
| **Display** | 🔶 Partially working | The display is scrambled unless there is an external monitor connected through usb-c|
| **Trackpad** |  🔶 Partially working |Left mouse click highlights instead of normal click.|
| **iMessages and App Store** | ❌ Not tested ||
| **Speakers and Headphones** | ❌ Not tested ||
| **Built-in Microphone** | ❌ Not tested ||
| **Webcam** | ❌ Not tested ||
| **Wi-Fi/BT** | ✅ Working | Requires [heliport app](https://github.com/OpenIntelWireless/HeliPort/releases) for WIFI.|
| **Thunderbolt/USB-C** | ❌ Not tested||
| **Touchscreen** |❌ Not tested||
| **SSD** | ✅ Working ||
| **Fingerprint reader** | ❌ Not working | Probably will never work, disabled to save power. |
| **Windows Hello** | ❌ Not working | Probably will never work, disabled to save power. |
| **SD Reader** | ✅ Working ||

# Bios
## Info
This is for bios version 1.2.0, but make sure the values are valid for your bios, whatever the version.
## CFG Lock enable

This should be done in macOS or linux.

1. Copy contents of Bios modification to Downloads folder (~/Downloads/HERE).
2. Run cfglock.sh as sudo.
3. Make sure the values are correct.
4. Edit the script, uncomment putvar and run as sudo again.