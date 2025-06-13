#!/bin/bash
apt update -y
apt install unzip curl -y
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list
apt update -y
apt install nomad docker.io -y

mkdir -p /opt/nomad
cat <<EOF > /etc/nomad.d/server.hcl
server {
  enabled = true
  bootstrap_expect = 3
}
data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"
EOF

nomad agent -config=/etc/nomad.d/server.hcl > /var/log/nomad.log 2>&1 &
