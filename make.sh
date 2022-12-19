#!/bin/bash
set -eu -o pipefail -E

while getopts t:a: flag
do
    case "${flag}" in
        t) tailnet=${OPTARG};;
        a) authkey=${OPTARG};;

    esac
done
echo "Tailnet: $tailnet";
echo "Authkey: $authkey";

auth_key=$(tr <.authkey -d '[:space:]')
tailscale_version="1.22.2"

echo "Building..."
mkdir -p build

for i in "linux amd64" "linux arm" "linux arm64" "linux 386" "darwin amd64" "darwin arm64" "windows amd64" "windows 386"; do
    i=($i)
    os="${i[0]}"
    arch="${i[1]}"
    dist="$os-$arch"

    echo "+ $dist"

    # only download files if not exist
    # to force an update, simply clear your "build" directory
    if [ -z "$(ls "build/$dist" 2>/dev/null)" ]; then
        mkdir -p "build/$dist"
        if [ "$os" = "windows" ]; then
            if [ "$arch" = "386" ]; then
                axel "https://pkgs.tailscale.com/stable/tailscale-setup-$tailscale_version-x86.msi" -o build/tailscale.msi
            else
                axel "https://pkgs.tailscale.com/stable/tailscale-setup-$tailscale_version-$arch.msi" -o build/tailscale.msi
            fi
            rm -rf build/tmp || true
            mkdir build/tmp
            msiextract build/tailscale.msi -C build/tmp >/dev/null
            rm build/tailscale.msi
            find build/tmp -type f \( -name "tailscale*.exe" -or -name "wintun.dll" \) -exec mv {} "build/$dist" \;
            rm -rf build/tmp
            if [ -z "$(ls "build/$dist" 2>/dev/null)" ]; then
                echo "Failed to extract required binaries"
                exit 1
            fi
        else
            (cd tailscale && GOOS="$os" GOARCH="$arch" ./build_dist.sh -o "../build/$dist/" -ldflags="-s -w" -trimpath tailscale.com/cmd/tailscale)
            (cd tailscale && GOOS="$os" GOARCH="$arch" ./build_dist.sh -o "../build/$dist/" -ldflags="-s -w" -trimpath tailscale.com/cmd/tailscaled)
        fi
    fi

    if [ "$os" = "windows" ]; then
        cp windows.cmd build/tsbolt.tmp
    else
        cp unix.sh build/tsbolt.tmp
    fi

    sed -i "" "s/__AUTHKEY__/$auth_key/" build/tsbolt.tmp
    (cd "build/$dist" && GZIP=-9 tar -czf - ./*) | base64 >>build/tsbolt.tmp

    if [ "$os" = "windows" ]; then
        mv build/tsbolt.tmp "build/tsbolt-$dist.cmd"
    elif [ "$os" = "darwin" ]; then
        mv build/tsbolt.tmp "build/tsbolt-$dist.command"
    else
        mv build/tsbolt.tmp "build/tsbolt-$dist.sh"
    fi
done

echo "Done!"
