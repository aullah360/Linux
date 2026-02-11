#!/bin/bash
set -e

echo "=== Updating system ==="
sudo apt update -y && sudo apt upgrade -y

echo "=== Installing dependencies ==="
sudo apt install -y curl wget jq libx11-6 libxdamage1 libxfixes3 libasound2

echo "=== Fetching latest RustDesk ARMHF release ==="
LATEST_URL=$(curl -s https://api.github.com/repos/rustdesk/rustdesk/releases/latest \
  | jq -r '.assets[] | select(.name | test("armhf.deb$")) | .browser_download_url')

if [ -z "$LATEST_URL" ]; then
  echo "ERROR: No ARMHF RustDesk build found."
  exit 1
fi

echo "Latest package: $LATEST_URL"
wget -O rustdesk-latest-armhf.deb "$LATEST_URL"

echo "=== Installing RustDesk ==="
sudo dpkg -i rustdesk-latest-armhf.deb || sudo apt --fix-broken install -y

echo "=== Creating systemd service ==="
sudo tee /etc/systemd/system/rustdesk.service >/dev/null << 'EOF'
[Unit]
Description=RustDesk Remote Desktop Service
After=network.target

[Service]
ExecStart=/usr/bin/rustdesk --service
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "=== Reloading systemd ==="
sudo systemctl daemon-reload

echo "=== Enabling and starting RustDesk ==="
sudo systemctl enable rustdesk
sudo systemctl start rustdesk

echo "=== RustDesk installation complete ==="
echo "RustDesk is now running and will start automatically on boot."
