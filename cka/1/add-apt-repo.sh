#!/bin/bash

mapfile -t INSTANCES < <(gcloud compute instances list --format="value(name,zone)")
TOTAL=${#INSTANCES[@]}
COUNT=1

for entry in "${INSTANCES[@]}"; do
  name=$(awk '{print $1}' <<< "$entry")
  zone=$(awk '{print $2}' <<< "$entry")

  echo "[$COUNT/$TOTAL] Adding APT repo to $name in $zone..."

  gcloud compute ssh "$name" --zone="$zone" --quiet --command='
    set -e
    echo "Running on $(hostname)"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
      sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
      sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
    echo "Success on $(hostname)"
  ' || echo "❌ FAILED on $name $zone"

  COUNT=$((COUNT + 1))
done


#while read name zone; do
#  echo "add apt repo $name in $zone"
#  gcloud compute ssh $name --zone="$zone" --command="sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
#  gcloud compute ssh $name --zone="$zone" --command="echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list"
#done < <(gcloud compute instances list --format="value(name,zone)") 

#while read name zone; do
#  echo "add apt repo $name in $zone"#

#  gcloud compute ssh "$name" --zone="$zone" --command="bash -c '
#    set -e
#    sudo mkdir -p /etc/apt/keyrings || true
#    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key |
#      sudo gpg --dearmor --no-tty --batch -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || true
#  '" || echo "[!] Failed: $name (apt-key)"

#  gcloud compute ssh "$name" --zone="$zone" --command="bash -c '
#    echo \"deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /\" |
#      sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
#  '" || echo "[!] Failed: $name (repo add)"

#done < <(gcloud compute instances list --format="value(name,zone)")

