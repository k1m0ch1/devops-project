gcloud compute instances list --format="value(name,zone)" | while read name zone; do
echo "Restarting $name in $zone"
  gcloud compute instances reset "$name" --zone="$zone"
done

