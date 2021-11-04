# TailScale Bolt

> Create self-contained, 1-click scripts for any OS, which connect any computer to your TailScale network.

## Supported platforms

- Linux
- macOS
- Windows

## Usage

1. Create a new `assets/` directory and place your TailScale assets in the following way:
   ```
   assets
   ├── .authkey
   ├── linux-amd64
   │   ├── tailscale
   │   └── tailscaled
   ├── linux-arm64
   │   ├── tailscale
   │   └── tailscaled
   ├── macos-amd64
   │   ├── tailscale
   │   └── tailscaled
   └── windows-amd64
       ├── tailscale-ipn.exe
       ├── tailscale.exe
       ├── tailscaled.exe
       └── wintun.dll
   ```
2. Run [make.sh](make.sh)

The resulting scripts will be generated in a `build/` directory.

> ### :warning: Currently, Windows script generation is only supported under WSL on Windows.
