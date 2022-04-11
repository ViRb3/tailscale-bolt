# TailScale Bolt

> Create self-contained, 1-click scripts, which connect any computer to your TailScale network.

## Supported platforms

- Linux (amd64, arm, arm64, 386)
- macOS (amd64, arm64)
- Windows (amd64, arm64\*, 386)

> \* Works through emulation, simply use the 386 build.

## Usage

1. Create a new file `.authkey` in the root directory of this project and paste your TailScale auth key, without any spaces or new lines.

2. Install the dependencies:
   ```
   msitools axel
   ```
3. Run [make.sh](make.sh).

The resulting scripts will be generated in a `build/` directory.

**NOTE:** Due to platform limitations, closed-source binaries for Windows have to be downloaded from the official TailScale server. These downloads are cached and reused on subsequent builds. If you want to force a full rebuild, simply delete the `build/` directory.

**NOTE2:** TailScale does not currently allow two instances to run at the same time. To work around this, this script will deactivate any existing installation. If you used TailScale before running this script, you _will_ need to re-authenticate afterwards.
