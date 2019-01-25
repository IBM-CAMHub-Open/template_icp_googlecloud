provider "google-beta" {
}

resource "google_filestore_instance" "icp-registry" {

  #count = "${var.master["nodes"] > 1 ? 1 : 0}"

  provider = "google-beta"

  name = "${var.deployment}-${random_id.clusterid.hex}-registry-fs"
  zone = "${format("%s-%s", var.region, var.zone)}"
  tier = "PREMIUM"

  file_shares {
    capacity_gb = 2560
    name        = "icpregistry"
  }

  networks {
    network = "${google_compute_network.icp.name}"
    modes   = ["MODE_IPV4"]
  }
}

/*
resource "google_filestore_instance" "icp-audit" {
  provider = "google-beta"

  name = "${var.deployment}-${random_id.clusterid.hex}-audit-fs"
  zone = "${format("%s-%s", var.region, var.zone)}"
  tier = "PREMIUM"

  file_shares {
    capacity_gb = 2560
    name        = "icpaudit"
  }

  networks {
    network = "${google_compute_network.icp.name}"
    modes   = ["MODE_IPV4"]
  }
  
}
*/