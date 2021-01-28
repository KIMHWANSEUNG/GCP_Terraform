// Configure the Google Cloud provider
provider "google" {
 credentials = "${file("credentials.json")}"
 project     = "terraform-test-302307"
 region      = "us-central1"
 zone        = "us-central1-a"
}

//VM instances Group Manager
resource "google_compute_instance_group_manager" "instance_manager"{
  name = "bespin-khs-group-manager"
  base_instance_name = "app"
  target_size = 3
  version {
    instance_template = google_compute_instance_template.vm_template.id
  }
}
//source image
data "google_compute_image" "my_image"{
  family = "ubuntu-1804-lts"
  project = "ubuntu-os-cloud"
}

//VM instance template
resource "google_compute_instance_template" "vm_template"{
  name = "bespin-khs-template"
  machine_type = "n1-standard-1"
  disk {
    source_image = data.google_compute_image.my_image.id
  	auto_delete = true
	  disk_size_gb = 10
    disk_type = "pd-standard"
  }
  tags = ["khs-tags"]

  network_interface {
    network = "default"
  }
}

//compute network
resource "google_compute_network" "vpc_network" {
  name = "bespin-khs-network"
  routing_mode = "GLOBAL"
}

// compute subnetwork
resource "google_compute_subnetwork" "vpc_subnet"{
  name = "bespin-khs-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network = google_compute_network.vpc_network.id
  log_config{
    aggregation_interval = "INTERVAL_5_MIN"
    flow_sampling = 0.5
  }
}

//Google compute firewall
resource "google_compute_firewall" "vm_firewall"{
  name = "bespin-khs-firewall"
  network = google_compute_network.vpc_network.name
  
  allow {
    protocol = "tcp"
    ports = ["80","443"]
  }

  target_tags = ["khs-tags"]
}

data "google_client_openid_userinfo" "me"{
}

resource "google_os_login_ssh_public_key" "firewall_ssh"{
  user = data.google_client_openid_userinfo.me.email
  key = file("./gcp_rsa.pub")
}

resource "google_redis_instance" "vpc_redis" {
  name = "bespin-khs-redis"
  memory_size_gb = 1
  authorized_network = google_compute_network.vpc_network.id
  redis_version = "REDIS_4_0"
  tier = "BASIC"
}