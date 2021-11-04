#!/bin/bash
set -eu -o pipefail -E

AUTHKEY=$(tr <assets/.authkey -d '[:space:]')

echo "Building..."
rm -rf build >/dev/null 2>&1 || true
mkdir -p build

dists=("linux-amd64" "linux-arm64" "macos-amd64")
for dist in "${dists[@]}"; do
    echo "+ $dist"
    cp unix.sh "build/tsbolt-$dist.sh"
    sed -i "s/__AUTHKEY__/$AUTHKEY/" "build/tsbolt-$dist.sh"
    (cd "assets/$dist" && XZ_OPT=-9 tar -cJf - ./*) | base64 -w 128 | sed 's/^/#/' >>"build/tsbolt-$dist.sh"
done

cd build
for f in *; do
    name=$(basename -- "$f")
    name="${name%.*}"
    if [[ $f == *-macos-* ]]; then
        mv "$f" "$name.command"
        f="$name.command"
    fi
    chmod 0777 "$f"
    zip -9 "$name.zip" "$f"
    rm "$f"
done
cd -

echo "+ windows-amd64"
cp windows.cmd build/tsbolt-windows-amd64.cmd
sed -i "s/__AUTHKEY__/$AUTHKEY/" build/tsbolt-windows-amd64.cmd
cmd.exe /c "Compressed2TXT/Compressed 2 TXT.bat" assets/windows-amd64/*
tail -n +3 "assets/windows-amd64/"*~.bat >>build/tsbolt-windows-amd64.cmd
rm "assets/windows-amd64/"*~.bat

echo "Done!"
