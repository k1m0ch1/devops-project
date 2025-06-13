provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "ubuntu_vm" {
  count        = 4
  name         = "ubuntu-vm-${count.index}"
  machine_type = "e2-standard-2" # 2 vCPU, 2 GB RAM

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    network = "default"

    access_config {
      # Include this block to give the instance a public IP
    }
  }

  tags = ["ubuntu"]
}

