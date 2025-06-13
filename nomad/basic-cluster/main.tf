terraform {
  required_providers{
    google = {
      source    = "hashicorp/google"
      version   = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.regions.southeastfirst.region
  zone    = var.regions.southeastfirst.zone
}

resource "google_compute_network" "nomad_net" {
  name    = "basic-nomad-network"
}

resource "google_compute_subnetwork" "nomad_subnet_southeastfirst" {
  name            = "nomad-subnet-southeast-first"
  ip_cidr_range   = "10.10.1.0/24"
  region          = var.regions.southeastfirst.region
  network         = google_compute_network.nomad_net.id 
}

resource "google_compute_subnetwork" "nomad_subnet_southeastsecond" {
  name            = "nomad-subnet-southest-second"
  ip_cidr_range   = "10.10.2.0/24"
  region          = var.regions.southeastsecond.region 
  network         = google_compute_network.nomad_net.id 
}

resource "google_compute_subnetwork" "nomad_subnet_south" {
  name            = "nomad-subnet-south"
  ip_cidr_range   = "10.10.3.0/24"
  region          = var.regions.south.region
  network         = google_compute_network.nomad_net.id 
}

resource "google_compute_firewall" "allow_internal" {
  name            = "allow-internal"
  network         = google_compute_network.nomad_net.name 

  allow {
    protocol = "tcp"
    ports    = ["4646", "4647", "4648", "22", "51820"]
  }

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  target_tags       = ["nomad", "internal"]
}

resource "google_compute_firewall" "allow_ssh_external" {
  name            = "allow-ssh-to-vpn"
  network         = google_compute_network.nomad_net.name 

  allow {
    protocol = "tcp"
    ports   = ["22", "51820"]
  }
  
  source_ranges     = ["0.0.0.0/0"]
  target_tags       = ["vpn"]
}

resource "google_compute_instance" "nomad_server_southeastfirst" {
  name                     = "nomad-server-southeastfirst-${count.index + 1}"
  count                    = 1 
  machine_type             = "e2-medium"
  tags                     = ["nomad", "server", "production", "internal"]
  metadata_startup_script  = file("${path.module}/nomad-server/server-install.sh")
  zone                     = var.regions.southeastfirst.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network           = google_compute_network.nomad_net.id 
    subnetwork        = google_compute_subnetwork.nomad_subnet_southeastfirst.id 
    network_ip        = "10.10.1.1${count.index + 1}"
  }
}

resource "google_compute_instance" "nomad_server_southeastsecond" {
 name                     = "nomad-server-southeastsecond-${count.index + 1}"
 count                    = 1 
 machine_type             = "e2-medium"
 tags                     = ["nomad", "server", "production", "internal"]
 metadata_startup_script  = file("${path.module}/nomad-server/server-install.sh")
 zone                     = var.regions.southeastsecond.zone

 boot_disk {
   initialize_params {
     image = "ubuntu-os-cloud/ubuntu-2204-lts"
   }
 }

 network_interface {
   network            = google_compute_network.nomad_net.id 
   subnetwork         = google_compute_subnetwork.nomad_subnet_southeastsecond.id 
   network_ip         = "10.10.2.1${count.index + 1}"
 }
}

resource "google_compute_instance" "nomad_server_south" {
  name                     = "nomad-server-south-${count.index + 1}"
  count                    = 1
  machine_type             = "e2-medium"
  tags                     = ["nomad", "server", "production", "internal"]
  metadata_startup_script  = file("${path.module}/nomad-server/server-install.sh")
  zone                     = var.regions.south.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network           = google_compute_network.nomad_net.id 
    subnetwork        = google_compute_subnetwork.nomad_subnet_south.id 
    network_ip        = "10.10.3.1${count.index + 1}"
  }
}

resource "google_compute_instance" "nomad_client_southeastfirst" {
  name            = "nomad-client-southeastfirst-${count.index +1}"
  count           = 2 
  machine_type    = "e2-standard-2"
  zone            = var.regions.southeastfirst.zone 
  tags            = ["nomad", "client", "production", "internal"]
  metadata_startup_script  = file("${path.module}/nomad-client/client-install.sh")

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network           = google_compute_network.nomad_net.id 
    subnetwork        = google_compute_subnetwork.nomad_subnet_southeastfirst.id 
    network_ip        = "10.10.1.10${count.index + 1}"
  }
}

resource "google_compute_instance" "nomad_client_south" {
  name            = "nomad-client-south-${count.index +1}"
  count           = 0 
  machine_type    = "e2-standard-2"
  zone            = var.regions.south.zone 
  tags            = ["nomad", "client", "production", "internal"]
  metadata_startup_script  = file("${path.module}/nomad-client/client-install.sh")

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network           = google_compute_network.nomad_net.id 
    subnetwork        = google_compute_subnetwork.nomad_subnet_south.id 
    network_ip        = "10.10.3.10${count.index + 1}"
  }
}

resource "google_compute_instance" "vpn" {
  name          = "vpn-server"
  machine_type  = "e2-micro"
  zone          = var.regions.southeastfirst.zone 
  tags          = ["vpn", "internal"]
  metadata_startup_script = file("${path.module}/vpn/wireguard-install.sh")

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network     = google_compute_network.nomad_net.id 
    subnetwork  = google_compute_subnetwork.nomad_subnet_southeastfirst.id 
    network_ip  = "10.10.1.200"

    access_config {}
  }

}
