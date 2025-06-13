#!/bin/bash

# Path to service account file
KEY_FILE="sa.json"

# Step 1: Activate the service account
gcloud auth activate-service-account --key-file="$KEY_FILE"

# Step 2: Extract client_email from JSON
CLIENT_EMAIL=$(jq -r '.client_email' "$KEY_FILE")

# Step 3: Extract project ID from email (after '@' and before '.iam')
PROJECT_ID=$(echo "$CLIENT_EMAIL" | sed -E 's/.*@(.*)\.iam.*/\1/')

# Update gcp.yml with the extracted PROJECT_ID
sed -i "s/^projects:.*/projects:\n  - $PROJECT_ID/" gcp.yml

# Step 4: Set gcloud project
gcloud config set project "$PROJECT_ID"

gcloud compute instances create "c1-cp1" --project="$PROJECT_ID" --zone=us-central1-a --machine-type=e2-standard-2 --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-balanced --tags=ubuntu

gcloud compute instances create "c1-node1" --project="$PROJECT_ID" --zone=us-central1-a --machine-type=e2-standard-2 --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-balanced --tags=ubuntu

gcloud compute instances create "c1-node2" --project="$PROJECT_ID" --zone=us-central1-a --machine-type=e2-standard-2 --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-balanced --tags=ubuntu

gcloud compute instances create "c1-node3" --project="$PROJECT_ID" --zone=us-central1-a --machine-type=e2-standard-2 --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-balanced --tags=ubuntu

# enforce to ssh 
gcloud compute ssh c1-cp1 --command="uname -a"
gcloud compute ssh c1-node1 --command="uname -a"
gcloud compute ssh c1-node2 --command="uname -a"
gcloud compute ssh c1-node3 --command="uname -a"

export ANSIBLE_SSH_COMMON_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ansible c1-cp1 -i gcp.yml -m ping --private-key ~/.ssh/google_compute_engine
ansible c1-node1 -i gcp.yml -m ping --private-key ~/.ssh/google_compute_engine
ansible c1-node2 -i gcp.yml -m ping --private-key ~/.ssh/google_compute_engine
ansible c1-node3 -i gcp.yml -m ping --private-key ~/.ssh/google_compute_engine

ansible-playbook -i gcp.yml disable_swap.yml --private-key ~/.ssh/google_compute_engine

gcloud compute instances list --format="value(name,zone)" | while read name zone; do
echo "Restarting $name in $zone"
  gcloud compute instances reset "$name" --zone="$zone"
done

ansible-playbook -i gcp.yml containerd.yml --private-key ~/.ssh/google_compute_engine
