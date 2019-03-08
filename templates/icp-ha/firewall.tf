resource "google_compute_firewall" "boot-node" {
  name    = "${var.deployment}-${random_id.clusterid.hex}-boot-allow-8500"
  network = "${google_compute_network.icp.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["8500"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["icp-boot-${random_id.clusterid.hex}"]
}

resource "google_compute_firewall" "cluster-node-ssh" {
  name    = "${var.deployment}-${random_id.clusterid.hex}-cluster-allow-ssh"
  network = "${google_compute_network.icp.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["icp-cluster-${random_id.clusterid.hex}"]
}

resource "google_compute_firewall" "cluster-traffic" {
  name    = "${var.deployment}-${random_id.clusterid.hex}-allow-cluster"
  network = "${google_compute_network.icp.self_link}"

  allow {
    protocol = "all"
  }

  priority = 800

  source_tags = [
    "icp-cluster-${random_id.clusterid.hex}"
  ]  
   
  source_ranges = [
    "${google_compute_subnetwork.icp_region_subnet.ip_cidr_range}"
  ]
  
  target_tags = ["icp-cluster-${random_id.clusterid.hex}"]
}

#####Master####

resource "google_compute_firewall" "master" {
  name    = "${var.deployment}-${random_id.clusterid.hex}-master-allow"
  network = "${google_compute_network.icp.self_link}"

  allow {
    protocol = "tcp"
    ports = [
      "8443", "9443", "8001", "8500", "8600"
    ]
  }

  source_ranges = [ "0.0.0.0/0" ]
  target_tags = [
    "icp-cluster-${random_id.clusterid.hex}"
  ]
}

###########

resource "google_compute_firewall" "proxy" {
  name    = "${var.deployment}-${random_id.clusterid.hex}-proxy-allow"
  network = "${google_compute_network.icp.self_link}"

  allow {
    protocol = "tcp"
    ports = [
      "80", "443", "30000-32767"
    ]
  }

  allow {
    protocol = "udp"
    ports = [
      "30000-32767"
    ]
  }
  source_ranges = [ "0.0.0.0/0" ]
  target_tags = [
    "icp-cluster-${random_id.clusterid.hex}"
  ]
}


resource "google_compute_firewall" "allow_ports_outbound" {

  name = "allowports-out-${random_id.clusterid.hex}"
  
  network = "${google_compute_network.icp.self_link}"

  direction = "EGRESS" 

  allow {
    protocol = "all"
  }
  
  destination_ranges = [ "0.0.0.0/0", "${google_compute_subnetwork.icp_region_subnet.ip_cidr_range}" ]
 
}
