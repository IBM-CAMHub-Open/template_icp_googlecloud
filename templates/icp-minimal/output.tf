###
output "ibm_cloud_private_admin_url" {
  value = "https://${google_compute_instance.icp-master.network_interface.0.access_config.0.assigned_nat_ip}:8443"
}

output "ICP Registry URL" {
  value = "https://${google_compute_instance.icp-master.network_interface.0.access_config.0.assigned_nat_ip}:8500"
}

output "ICP Kubernetes API URL" {
  value = "https://${google_compute_instance.icp-master.network_interface.0.access_config.0.assigned_nat_ip}:8001"
}

output "ibm_cloud_private_cluster_name" {
  value = "${var.deployment}"
}

output "ibm_cloud_private_cluster_CA_domain_name" {
  value = "${var.deployment}.icp"
}

output "ibm_cloud_private_admin_user" {
  value = "admin"
}

output "ibm_cloud_private_admin_password" {
  value = "${local.icppassword}"
}

output "ibm_cloud_private_boot_ip" {
  value = "${google_compute_instance.icp-master.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "ibm_cloud_private_master_ip" {
  value = "${google_compute_instance.icp-master.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "ibm_cloud_private_ssh_user" {
  value = "${var.ssh_user}"
}

output "ibm_cloud_private_ssh_key" {
  value = "${base64encode(tls_private_key.installkey.private_key_pem)}"
}

output "connection_name" {
	value = "${var.deployment}${random_id.clusterid.hex}"
}
