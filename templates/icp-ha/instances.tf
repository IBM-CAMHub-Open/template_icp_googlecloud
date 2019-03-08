
data "google_compute_image" "base_compute_image" {
  project   = "${var.image_type["project"]}"
  family    = "${var.image_type["family"]}"
}

################## Docker disks
resource "google_compute_disk" "docker-master" {
  count = "${var.master["nodes"]}"

  name  = "${format("${lower(var.deployment)}-${random_id.clusterid.hex}-master%02d-dockervol", count.index + 1) }"
  type  = "pd-ssd"
  zone  = "${format("%s-%s", var.region, var.zone)}"
  
  size = "${var.master["docker_vol_size"]}"
}

###
resource "google_compute_disk" "docker-worker" {

  count = "${var.worker["nodes"]}"

  name  = "${format("${lower(var.deployment)}-${random_id.clusterid.hex}-worker%02d-dockervol", count.index + 1) }"
  type  = "pd-ssd"
  zone  = "${format("%s-%s", var.region, var.zone)}"
  
  size = "${var.worker["docker_vol_size"]}"
}

###
resource "google_compute_disk" "docker-boot" {

  count = "${var.boot["nodes"]}"

  name  = "${format("${lower(var.deployment)}-${random_id.clusterid.hex}-boot%02d-dockervol", count.index + 1) }"
  type  = "pd-ssd"
  zone  = "${format("%s-%s", var.region, var.zone)}"
  
  size = "${var.boot["docker_vol_size"]}"
}

###
resource "google_compute_disk" "docker-proxy" {

  count = "${var.proxy["nodes"]}"
  
  name  = "${format("${lower(var.deployment)}-${random_id.clusterid.hex}-proxy%02d-dockervol", count.index + 1) }"
  type  = "pd-ssd"
  zone  = "${format("%s-%s", var.region, var.zone)}"
  
  size = "${var.proxy["docker_vol_size"]}"
}

###
resource "google_compute_disk" "docker-mgmt" {

  count = "${var.mgmt["nodes"]}"

  name  = "${format("${lower(var.deployment)}-${random_id.clusterid.hex}-mgmt%02d-dockervol", count.index + 1) }"
  type  = "pd-ssd"
  zone  = "${format("%s-%s", var.region, var.zone)}"
  
  size = "${var.mgmt["docker_vol_size"]}"
}

###
resource "google_compute_disk" "docker-va" {

  count = "${var.va["nodes"]}"

  name  = "${format("${lower(var.deployment)}-${random_id.clusterid.hex}-va%02d-dockervol", count.index + 1) }"
  type  = "pd-ssd"
  zone  = "${format("%s-%s", var.region, var.zone)}"
  
  size = "${var.va["docker_vol_size"]}"
}

##############################################
## Provision boot node
##############################################

resource "google_compute_instance" "icp-boot" {
  count = "${var.boot["nodes"]}"

  name         = "${format("${lower(var.deployment)}-boot%02d-${random_id.clusterid.hex}", count.index + 1) }"
  
  machine_type = "${format("custom-%s-%s", var.boot["cpu"], var.boot["memory"])}"
  zone         = "${format("%s-%s", var.region, var.zone)}"
  
  allow_stopping_for_update = true

  tags = [
    "${compact(list(
    "icp-boot-${random_id.clusterid.hex}",
    "icp-cluster-${random_id.clusterid.hex}"
    ))}"  
  ]
  
  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base_compute_image.self_link}"
      size="${var.boot["disk_size"]}"
      type = "pd-standard"      
    }
  }
  attached_disk {
	    source = "${google_compute_disk.docker-boot.name}"
  }
  network_interface {
    subnetwork  = "${google_compute_subnetwork.icp_region_subnet.self_link}"
    
    access_config {
         //Ephemeral IP
    }    
    
    
  }

  can_ip_forward = true

  metadata {
    sshKeys = <<EOF
${var.ssh_user}:${tls_private_key.installkey.public_key_openssh}
EOF
    user-data = <<EOF
#cloud-config
packages:
  - unzip
  - python
  - pv
  - nfs-common
users:
- name: ${var.ssh_user}
  groups: [ wheel ]
  sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
  shell: /bin/bash
  ssh-authorized-keys:
  - ${tls_private_key.installkey.public_key_openssh}
write_files:
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/bootstrap.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/bootstrap.sh
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/download_icp.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/download_icp.sh  
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/load_image.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/load_image.sh 
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/download_docker.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/download_docker.sh  
- path: /etc/registry/registry-cert.pem
  permissions: '600'
  encoding: b64
  content: ${base64encode("${tls_self_signed_cert.registry_cert.cert_pem}")}
- path: /etc/registry/registry-key.pem
  permissions: '600'
  encoding: b64
  content: ${base64encode("${tls_private_key.registry_key.private_key_pem}")}         
- path: /etc/docker/certs.d/${local.registry_server}:8500/ca.crt
  permissions: '600'
  encoding: b64
  content: ${base64encode("${tls_self_signed_cert.registry_cert.cert_pem}")}         
disk_setup:
  /dev/sdb:
     table_type: 'gpt'
     layout: True
     overwrite: True
fs_setup:
  - label: None
    filesystem: 'ext4'
    device: '/dev/sdb'
    partition: 'auto'
mounts:
- [ sdb, /var/lib/docker ]
runcmd:
- echo '127.0.0.1 ${local.registry_server}' >> /etc/hosts
- /opt/ibm/scripts/download_docker.sh ${var.docker_package_location != "" ? "-d ${var.docker_package_location}" : "" } -u ${var.download_user} -p ${var.download_user_password} 
- /opt/ibm/scripts/bootstrap.sh -u ${var.ssh_user} ${local.docker_package_uri != "" ? "-p ${local.docker_package_uri}" : "" } -d /dev/sdb
EOF
  }
  
  service_account {
    email = "${var.service_account_email}"
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  
}

##############################################
## Provision cluster nodes
##############################################

resource "google_compute_instance" "icp-master" {
  count = "${var.master["nodes"]}"

  name         = "${format("${lower(var.deployment)}-master%02d-${random_id.clusterid.hex}", count.index + 1) }"
  machine_type = "${format("custom-%s-%s", var.master["cpu"], var.master["memory"])}"
  zone         = "${format("%s-%s", var.region, var.zone)}"
  
  allow_stopping_for_update = true

  tags = [
    "${compact(list(
    "icp-master-${random_id.clusterid.hex}",
    "${var.proxy["nodes"] < 1 ? "icp-proxy-${random_id.clusterid.hex}" : ""}",
    "icp-cluster-${random_id.clusterid.hex}"
    ))}"  
  ]

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base_compute_image.self_link}"
      size="${var.master["disk_size"]}"
    }
  }
  attached_disk {
    source = "${element(google_compute_disk.docker-master.*.self_link, count.index)}"
  }
    
  network_interface {
    subnetwork  = "${google_compute_subnetwork.icp_region_subnet.self_link}"
    
    access_config {
         //Ephemeral IP
    }    
    
  }
  
  can_ip_forward = true
  
  metadata {
    sshKeys = <<EOF
${var.ssh_user}:${tls_private_key.installkey.public_key_openssh}
EOF
    user-data = <<EOF
#cloud-config
packages:
  - unzip
  - python
write_files:
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/bootstrap.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/bootstrap.sh
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/download_icp.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/download_icp.sh  
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/load_image.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/load_image.sh 
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/download_docker.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/download_docker.sh  
- path: /etc/docker/certs.d/${local.registry_server}:8500/ca.crt
  permissions: '600'
  encoding: b64
  content: ${base64encode("${tls_self_signed_cert.registry_cert.cert_pem}")}         
disk_setup:
  /dev/sdb:
     table_type: 'gpt'
     layout: True
     overwrite: True
users:
- name: ${var.ssh_user}
  groups: [ wheel ]
  sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
  shell: /bin/bash
  ssh-authorized-keys:
  - ${tls_private_key.installkey.public_key_openssh}
fs_setup:
  - label: None
    filesystem: 'ext4'
    device: '/dev/sdb'
    partition: 'auto'
mounts:
- [ 'sdb', '/var/lib/docker' ]
- [ '${google_filestore_instance.icp-registry.networks.0.ip_addresses.0}:/${google_filestore_instance.icp-registry.file_shares.0.name}', '/var/lib/registry', 'nfs', 'defaults', '0', '0' ]
- [ '${google_filestore_instance.icp-registry.networks.0.ip_addresses.0}:/${google_filestore_instance.icp-registry.file_shares.0.name}', '/var/lib/icp/audit', 'nfs', 'defaults', '0', '0' ]
runcmd:
- echo '${google_compute_instance.icp-boot.network_interface.0.network_ip} ${local.registry_server}' >> /etc/hosts
- /opt/ibm/scripts/download_docker.sh ${var.docker_package_location != "" ? "-d ${var.docker_package_location}" : "" } -u ${var.download_user} -p ${var.download_user_password} 
- /opt/ibm/scripts/bootstrap.sh -u ${var.ssh_user} ${local.docker_package_uri != "" ? "-p ${local.docker_package_uri}" : "" } -d /dev/sdb
EOF
  }  
  
  service_account {
    email = "${var.service_account_email}"
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

    
}

########## Worker
resource "google_compute_instance" "icp-worker" {
  count = "${var.worker["nodes"]}"

  name = "${format("${lower(var.deployment)}-worker%02d-${random_id.clusterid.hex}", count.index + 1) }"
  machine_type = "${format("custom-%s-%s", var.worker["cpu"], var.worker["memory"])}"
  zone         = "${format("%s-%s", var.region, var.zone)}"

  allow_stopping_for_update = true

  tags = [
    "${compact(list(
    "icp-worker-${random_id.clusterid.hex}",
    "icp-cluster-${random_id.clusterid.hex}"
    ))}"
  ]
  
  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base_compute_image.self_link}"
      size="${var.worker["disk_size"]}"
      type = "pd-standard"
    }
  }

  attached_disk {
    source = "${element(google_compute_disk.docker-worker.*.self_link, count.index)}"
  }
  
  network_interface {
    subnetwork  = "${google_compute_subnetwork.icp_region_subnet.self_link}"
    
    access_config {
         //Ephemeral IP
    }    
    
  }

  can_ip_forward = true

  metadata {
    sshKeys = <<EOF
${var.ssh_user}:${tls_private_key.installkey.public_key_openssh}
EOF
    user-data = <<EOF
#cloud-config
packages:
  - unzip
  - python
write_files:
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/bootstrap.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/bootstrap.sh
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/download_docker.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/download_docker.sh 
- path: /etc/docker/certs.d/${local.registry_server}:8500/ca.crt
  permissions: '600'
  encoding: b64
  content: ${base64encode("${tls_self_signed_cert.registry_cert.cert_pem}")}            
disk_setup:
  /dev/sdb:
     table_type: 'gpt'
     layout: True
     overwrite: True
users:
- name: ${var.ssh_user}
  groups: [ wheel ]
  sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
  shell: /bin/bash
  ssh-authorized-keys:
  - ${tls_private_key.installkey.public_key_openssh}
fs_setup:
  - label: None
    filesystem: 'ext4'
    device: '/dev/sdb'
    partition: 'auto'
mounts:
- [ sdb, /var/lib/docker ]
runcmd:
- echo '${google_compute_instance.icp-boot.network_interface.0.network_ip} ${local.registry_server}' >> /etc/hosts
- /opt/ibm/scripts/download_docker.sh ${var.docker_package_location != "" ? "-d ${var.docker_package_location}" : "" } -u ${var.download_user} -p ${var.download_user_password} 
- /opt/ibm/scripts/bootstrap.sh -u ${var.ssh_user} ${local.docker_package_uri != "" ? "-p ${local.docker_package_uri}" : "" } -d /dev/sdb
EOF
  }
/*
  # wait until cloud-init finishes
  provisioner "remote-exec" {
    connection {
      user          = "${var.ssh_user}"
      private_key   = "${tls_private_key.installkey.private_key_pem}"
    }

    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done"
    ]
  }
*/
  service_account {
    email = "${var.service_account_email}"
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  
}

resource "google_compute_instance" "icp-mgmt" {
  count = "${var.mgmt["nodes"]}"

  name = "${format("${lower(var.deployment)}-mgmt%02d-${random_id.clusterid.hex}", count.index + 1) }"
  machine_type = "${format("custom-%s-%s", var.mgmt["cpu"], var.mgmt["memory"])}"
  zone         = "${format("%s-%s", var.region, var.zone)}"

  allow_stopping_for_update = true

  tags = [
    "${compact(list(
    "icp-mgmt-${random_id.clusterid.hex}",
    "icp-cluster-${random_id.clusterid.hex}"
    ))}"
  ]

  
  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base_compute_image.self_link}"
      size="${var.mgmt["disk_size"]}"
      type = "pd-standard"
    }
  }

  attached_disk {
    source = "${element(google_compute_disk.docker-mgmt.*.self_link, count.index)}"
  }

  network_interface {
    subnetwork  = "${google_compute_subnetwork.icp_region_subnet.self_link}"
    
    access_config {
         //Ephemeral IP
    }    
    
  }
  
  can_ip_forward = true

  metadata {
    sshKeys = <<EOF
${var.ssh_user}:${tls_private_key.installkey.public_key_openssh}
EOF
    user-data = <<EOF
#cloud-config
packages:
  - unzip
  - python
write_files:
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/bootstrap.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/bootstrap.sh
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/download_docker.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/download_docker.sh 
- path: /etc/docker/certs.d/${local.registry_server}:8500/ca.crt
  permissions: '600'
  encoding: b64
  content: ${base64encode("${tls_self_signed_cert.registry_cert.cert_pem}")}            
disk_setup:
  /dev/sdb:
     table_type: 'gpt'
     layout: True
     overwrite: True
users:
- name: ${var.ssh_user}
  groups: [ wheel ]
  sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
  shell: /bin/bash
  ssh-authorized-keys:
  - ${tls_private_key.installkey.public_key_openssh}
fs_setup:
  - label: None
    filesystem: 'ext4'
    device: '/dev/sdb'
    partition: 'auto'
mounts:
- [ sdb, /var/lib/docker ]
runcmd:
- echo '${google_compute_instance.icp-boot.network_interface.0.network_ip} ${local.registry_server}' >> /etc/hosts
- /opt/ibm/scripts/download_docker.sh ${var.docker_package_location != "" ? "-d ${var.docker_package_location}" : "" } -u ${var.download_user} -p ${var.download_user_password} 
- /opt/ibm/scripts/bootstrap.sh -u ${var.ssh_user} ${local.docker_package_uri != "" ? "-p ${local.docker_package_uri}" : "" } -d /dev/sdb
EOF
  }
  /*
  # wait until cloud-init finishes
  provisioner "remote-exec" {
    connection {
      user          = "${var.ssh_user}"
      private_key   = "${tls_private_key.installkey.private_key_pem}"
    }

    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done"
    ]
  }
*/
  service_account {
    email = "${var.service_account_email}"
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  
}

resource "google_compute_instance" "icp-va" {
  count = "${var.va["nodes"]}"

  name = "${format("${lower(var.deployment)}-va%02d-${random_id.clusterid.hex}", count.index + 1) }"
  machine_type = "${format("custom-%s-%s", var.va["cpu"], var.va["memory"])}"
  zone         = "${format("%s-%s", var.region, var.zone)}"
  
  allow_stopping_for_update = true

  tags = [
    "${compact(list(
    "icp-va-${random_id.clusterid.hex}",
    "icp-cluster-${random_id.clusterid.hex}"
    ))}"
  ]
  
  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base_compute_image.self_link}"
      size="${var.va["disk_size"]}"
      type = "pd-standard"
    }
  }

  attached_disk {
    source = "${element(google_compute_disk.docker-va.*.self_link, count.index)}"
  }
  
  network_interface {
    subnetwork  = "${google_compute_subnetwork.icp_region_subnet.self_link}"
    
    access_config {
         //Ephemeral IP
    }    
    
  }

  can_ip_forward = true

  metadata {
    sshKeys = <<EOF
${var.ssh_user}:${tls_private_key.installkey.public_key_openssh}"
EOF
    user-data = <<EOF
#cloud-config
packages:
  - unzip
  - python
write_files:
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/bootstrap.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/bootstrap.sh
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/download_docker.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/download_docker.sh 
- path: /etc/docker/certs.d/${local.registry_server}:8500/ca.crt
  permissions: '600'
  encoding: b64
  content: ${base64encode("${tls_self_signed_cert.registry_cert.cert_pem}")}            
disk_setup:
  /dev/sdb:
     table_type: 'gpt'
     layout: True
     overwrite: True
users:
- name: ${var.ssh_user}
  groups: [ wheel ]
  sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
  shell: /bin/bash
  ssh-authorized-keys:
  - ${tls_private_key.installkey.public_key_openssh}
fs_setup:
  - label: None
    filesystem: 'ext4'
    device: '/dev/sdb'
    partition: 'auto'
mounts:
- [ sdb, /var/lib/docker ]
runcmd:
- echo '${google_compute_instance.icp-boot.network_interface.0.network_ip} ${local.registry_server}' >> /etc/hosts
- /opt/ibm/scripts/download_docker.sh ${var.docker_package_location != "" ? "-d ${var.docker_package_location}" : "" } -u ${var.download_user} -p ${var.download_user_password} 
- /opt/ibm/scripts/bootstrap.sh -u ${var.ssh_user} ${local.docker_package_uri != "" ? "-p ${local.docker_package_uri}" : "" } -d /dev/sdb
EOF
  }
/*  
    # wait until cloud-init finishes
  provisioner "remote-exec" {
    connection {
      user          = "${var.ssh_user}"
      private_key   = "${tls_private_key.installkey.private_key_pem}"
    }

    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done"
    ]
  }
*/
  service_account {
    email = "${var.service_account_email}"
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  
}



resource "google_compute_instance" "icp-proxy" {
  count = "${var.proxy["nodes"]}"

  name = "${format("${lower(var.deployment)}-proxy%02d-${random_id.clusterid.hex}", count.index + 1) }"
  machine_type = "${format("custom-%s-%s", var.proxy["cpu"], var.proxy["memory"])}"
  zone         = "${format("%s-%s", var.region, var.zone)}"
  
  allow_stopping_for_update = true

  tags = [
    "${compact(list(
    "icp-proxy-${random_id.clusterid.hex}",
    "icp-cluster-${random_id.clusterid.hex}"
    ))}"
  ]
  
  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.base_compute_image.self_link}"
      size="${var.proxy["disk_size"]}"
      type = "pd-standard"      
    }
  }
  attached_disk {
    source = "${element(google_compute_disk.docker-proxy.*.self_link, count.index)}"
  }
  network_interface {
    subnetwork  = "${google_compute_subnetwork.icp_region_subnet.self_link}"
    
    access_config {
         //Ephemeral IP
    }    
    
  }

  can_ip_forward = true

  metadata {
    sshKeys = <<EOF
${var.ssh_user}:${tls_private_key.installkey.public_key_openssh}"
EOF
    user-data = <<EOF
#cloud-config
packages:
  - unzip
  - python
write_files:
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/bootstrap.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/bootstrap.sh
- encoding: b64
  content: ${base64encode(file("${path.module}/scripts/download_docker.sh"))}
  permissions: '0755'
  path: /opt/ibm/scripts/download_docker.sh 
- path: /etc/docker/certs.d/${local.registry_server}:8500/ca.crt
  permissions: '600'
  encoding: b64
  content: ${base64encode("${tls_self_signed_cert.registry_cert.cert_pem}")}            
disk_setup:
  /dev/sdb:
     table_type: 'gpt'
     layout: True
     overwrite: True
users:
- name: ${var.ssh_user}
  groups: [ wheel ]
  sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
  shell: /bin/bash
  ssh-authorized-keys:
  - ${tls_private_key.installkey.public_key_openssh}
fs_setup:
  - label: None
    filesystem: 'ext4'
    device: '/dev/sdb'
    partition: 'auto'
mounts:
- [ sdb, /var/lib/docker ]
runcmd:
- echo '${google_compute_instance.icp-boot.network_interface.0.network_ip} ${local.registry_server}' >> /etc/hosts
- /opt/ibm/scripts/download_docker.sh ${var.docker_package_location != "" ? "-d ${var.docker_package_location}" : "" } -u ${var.download_user} -p ${var.download_user_password} 
- /opt/ibm/scripts/bootstrap.sh -u ${var.ssh_user} ${local.docker_package_uri != "" ? "-p ${local.docker_package_uri}" : "" } -d /dev/sdb
EOF
  } 
  
  # wait until cloud-init finishes
  provisioner "remote-exec" {
    connection {
      user          = "${var.ssh_user}"
      private_key   = "${tls_private_key.installkey.private_key_pem}"
    }

    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done"
    ]
  }
 
  service_account {
    email = "${var.service_account_email}"
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  
}

