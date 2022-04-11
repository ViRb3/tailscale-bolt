#!/bin/bash
set -eu -o pipefail -E

#================================================================
AUTHKEY=__AUTHKEY__
#================================================================

function cleanup() {
    set +e
    trap - SIGINT SIGTERM ERR
    echo "Cleaning up..."
    sudo "$INSTALL_DIR/tailscale" logout >/dev/null 2>&1
    sudo pkill Tailscale
    sudo pkill tailscale
    sudo pkill tailscaled
    rm -r "$INSTALL_DIR" >/dev/null 2>&1
    rm -r /var/lib/tailscale/ >/dev/null 2>&1
    rm -d /run/tailscale/ >/dev/null 2>&1
    echo "Done!"
}
function error() {
    error_code=$?
    echo "There was an error!"
    cleanup
    exit $error_code
}
trap error SIGINT SIGTERM ERR

echo "Stopping any existing instances of TailScale..."
sudo pkill Tailscale || true
sudo pkill tailscale || true
sudo pkill tailscaled || true
rm -r /var/lib/tailscale/ >/dev/null 2>&1 || true
rm -d /run/tailscale/ >/dev/null 2>&1 || true

echo "Loading TailScale..."
PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR + 1; exit 0; }' "$0")
INSTALL_DIR="/tmp/tsbolt-kg93j1"
mkdir -p "$INSTALL_DIR"
tail -n +"$PAYLOAD_LINE" "$0" | base64 -d | tar -xzp -C "$INSTALL_DIR"
sudo "$INSTALL_DIR/tailscaled" >/dev/null 2>&1 &

echo "Starting VPN..."
echo "If nothing happens, close this script and restart it."
echo "If the issue persists, your auth key is likely invalid."
sudo "$INSTALL_DIR/tailscale" up --authkey "$AUTHKEY" --reset >/dev/null 2>&1

echo "VPN successfully initialized."
echo
echo "Your IP:"
echo
sudo "$INSTALL_DIR/tailscale" ip
echo
echo "Status:"
echo
sudo "$INSTALL_DIR/tailscale" status
echo
echo "If you need to access the CLI, it can be found here:"
echo "$INSTALL_DIR/tailscale"
echo
echo "When you are done, continue to remove TailScale."
read -n 1 -s -r -p $'Press any key to continue...\n'

cleanup
exit 0

#========================================================================================================================================

__PAYLOAD_BEGINS__
