resource "google_compute_address" "icp-master" {
  name = "${var.deployment}-${random_id.clusterid.hex}-master-addr"
}

resource "google_compute_target_pool" "icp-master" {
  name = "${var.deployment}-${random_id.clusterid.hex}-master"

  instances = [
    "${google_compute_instance.icp-master.*.self_link}"
  ]
}

resource "google_compute_forwarding_rule" "master-8001" {
  name        = "${var.deployment}-${random_id.clusterid.hex}-master-8001"
  description = "forward ICP master traffic to 8001"
  target      = "${google_compute_target_pool.icp-master.self_link}"
  ip_address  = "${google_compute_address.icp-master.self_link}"
  ip_protocol = "TCP"
  port_range  = "8001-8001"

  lifecycle {
    ignore_changes = [
      "ip_address"
    ]
  }
}

resource "google_compute_forwarding_rule" "master-8443" {
  name        = "${var.deployment}-${random_id.clusterid.hex}-master-8443"
  description = "forward ICP master traffic to 8443"

  target      = "${google_compute_target_pool.icp-master.self_link}"
  ip_address  = "${google_compute_address.icp-master.self_link}"
  ip_protocol = "TCP"
  port_range  = "8443-8443"

  lifecycle {
    ignore_changes = [
      "ip_address"
    ]
  }

}

resource "google_compute_forwarding_rule" "master-8500" {
  name        = "${var.deployment}-${random_id.clusterid.hex}-master-8500"
  description = "forward ICP master traffic to 8500"

  target      = "${google_compute_target_pool.icp-master.self_link}"
  ip_address  = "${google_compute_address.icp-master.self_link}"
  ip_protocol = "TCP"
  port_range  = "8500-8500"

  lifecycle {
    ignore_changes = [
      "ip_address"
    ]
  }
}

resource "google_compute_forwarding_rule" "master-8600" {
  name        = "${var.deployment}-${random_id.clusterid.hex}-master-8600"
  description = "forward ICP master traffic to 8600"

  target      = "${google_compute_target_pool.icp-master.self_link}"
  ip_address  = "${google_compute_address.icp-master.self_link}"
  ip_protocol = "TCP"
  port_range  = "8600-8600"

  lifecycle {
    ignore_changes = [
      "ip_address"
    ]
  }
}

resource "google_compute_forwarding_rule" "master-9443" {
  name        = "${var.deployment}-${random_id.clusterid.hex}-master-9443"
  description = "forward ICP master traffic to 9443"
  target      = "${google_compute_target_pool.icp-master.self_link}"
  ip_address  = "${google_compute_address.icp-master.self_link}"
  ip_protocol = "TCP"
  port_range  = "9443-9443"

  lifecycle {
    ignore_changes = [
      "ip_address"
    ]
  }
}

resource "google_compute_address" "icp-proxy" {
  name = "${var.deployment}-${random_id.clusterid.hex}-proxy-addr"
}

resource "google_compute_target_pool" "icp-proxy" {
  name = "${var.deployment}-${random_id.clusterid.hex}-proxy"

  instances = [
    "${google_compute_instance.icp-proxy.*.self_link}"
  ]
}

resource "google_compute_forwarding_rule" "proxy-80" {
  name        = "${var.deployment}-${random_id.clusterid.hex}-proxy-80"
  description = "forward ICP master traffic to 80"

  target      = "${google_compute_target_pool.icp-proxy.self_link}"
  ip_address  = "${google_compute_address.icp-proxy.self_link}"
  ip_protocol = "TCP"
  port_range  = "80-80"

  lifecycle {
    ignore_changes = [
      "ip_address"
    ]
  }
}


resource "google_compute_forwarding_rule" "proxy-443" {
  name        = "${var.deployment}-${random_id.clusterid.hex}-proxy-443"
  description = "forward ICP master traffic to 443"

  target      = "${google_compute_target_pool.icp-proxy.self_link}"
  ip_address  = "${google_compute_address.icp-proxy.self_link}"
  ip_protocol = "TCP"
  port_range  = "443-443"

  lifecycle {
    ignore_changes = [
      "ip_address"
    ]
  }
}


resource "google_compute_health_check" "master-8443" {
  name               = "${var.deployment}-${random_id.clusterid.hex}-master-8443"
  check_interval_sec = 5
  timeout_sec        = 5

  ssl_health_check {
    port = 8443
  }
}

resource "google_compute_health_check" "master-9443" {
  name               = "${var.deployment}-${random_id.clusterid.hex}-master-9443"
  check_interval_sec = 5
  timeout_sec        = 5

  ssl_health_check {
    port = 9443
  }
}

resource "google_compute_health_check" "master-8500" {
  name               = "${var.deployment}-${random_id.clusterid.hex}-master-8500"
  check_interval_sec = 5
  timeout_sec        = 5

  ssl_health_check {
    port = 8500
  }
}

resource "google_compute_health_check" "master-8600" {
  name               = "${var.deployment}-${random_id.clusterid.hex}-master-8600"
  check_interval_sec = 5
  timeout_sec        = 5

  ssl_health_check {
    port = 8600
  }
}

resource "google_compute_health_check" "master-8001" {
  name               = "${var.deployment}-${random_id.clusterid.hex}-master-8001"
  check_interval_sec = 5
  timeout_sec        = 5

  ssl_health_check {
    port = 8001
  }
}