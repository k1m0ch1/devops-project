#!/bin/bash

# Update & install dependencies
apt-get update -y
apt-get install -y unzip curl gnupg docker.io

# Install Nomad
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y nomad

# Enable Docker
systemctl enable docker
systemctl start docker

# Nomad config directory
mkdir -p /etc/nomad.d
mkdir -p /opt/nomad
chmod a+w /opt/nomad

# Nomad client configuration
cat <<EOF > /etc/nomad.d/client.hcl
client {
  enabled = true
  servers = ["<REPLACE_WITH_SERVER_PRIVATE_IP_1>", "<REPLACE_WITH_SERVER_PRIVATE_IP_2>", "<REPLACE_WITH_SERVER_PRIVATE_IP_3>"]
  options {
    "docker.auth.config" = "/root/.docker/config.json"
  }
}

data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"

log_level = "INFO"

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}
EOF

# Run Nomad as a service
cat <<EOF > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad Client Agent
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/nomad agent -config=/etc/nomad.d
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Start & enable Nomad
systemctl daemon-reexec
systemctl enable nomad
systemctl start nomad
