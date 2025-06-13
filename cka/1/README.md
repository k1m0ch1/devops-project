1. run the init.sh
2. gcloud compute ssh <all the machine to pair the key>
3. open the `gcp.yml` and then change the project key or ID
4. need to run `ansible all -i gcp.yml -m ping --private-key ~/.ssh/google_compute_engine` to make sure ansible could running it, this is kinda problem and makes the private key won't running
5. run disable_swap.yml `ansible-playbook -i gcp.yml disable_swap.yml --private-key ~/.ssh/google_compute_engine`
6. need to restart all service
7. run the `containerd.yml`
8. check the service with `checkup.yml`
