resource "google_compute_network" "icp" {
  name = "icp-network-${random_id.clusterid.hex}"
  auto_create_subnetworks = "false"
  description             = "ICP ${random_id.clusterid.hex} VPC"
  
}

resource "google_compute_subnetwork" "icp_region_subnet" {
  name          = "${var.deployment}-${random_id.clusterid.hex}-subnet"

  ip_cidr_range = "${var.subnet_cidr}"

  private_ip_google_access = true
  
  region        = "${var.region}"
  network       = "${google_compute_network.icp.self_link}"

  secondary_ip_range {
   range_name    = "podnet"
   ip_cidr_range = "${var.pod_network_cidr}"
  }
}
/*
module "nat" {
  source          = "GoogleCloudPlatform/nat-gateway/google"
  name            = "${var.deployment}-${random_id.clusterid.hex}-nat-"
  region          = "${var.region}"
  zone            = "${format("%s-%s", var.region, var.zone)}"  
  network         = "${google_compute_network.icp.name}"
  subnetwork      = "${google_compute_subnetwork.icp_region_subnet.name}"
}
*/