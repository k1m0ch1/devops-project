#!/bin/bash

# Update & install WireGuard
apt update -y
apt install -y wireguard qrencode

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

# Create config directory
WG_DIR="/etc/wireguard"
mkdir -p $WG_DIR
cd $WG_DIR

# Generate server keys
umask 077
wg genkey | tee server.key | wg pubkey > server.pub

PRIVATE_KEY=$(cat server.key)

# Server config
cat <<EOF > wg0.conf
[Interface]
PrivateKey = $PRIVATE_KEY
Address = 10.10.1.1/24
ListenPort = 51820
SaveConfig = true

# NAT to internet
PostUp = iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE
EOF

# Enable and start service
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
