module "gather_output" {
	dependsOn					= true
    source 						= "git::https://github.com/IBM-CAMHub-Open/template_icp_modules.git?ref=3.2.1//public_cloud_output"
	cluster_CA_domain 			= "${var.deployment}.icp"
	icp_master 					= "${list(google_compute_instance.icp-master.network_interface.0.access_config.0.assigned_nat_ip)}"
	ssh_user 					= "${var.ssh_user}"
	ssh_key_base64 				= "${base64encode(tls_private_key.installkey.private_key_pem)}"
	bastion_host 				= "${google_compute_instance.icp-master.network_interface.0.access_config.0.assigned_nat_ip}"
	bastion_user    			= "${var.ssh_user}"
    bastion_private_key_base64 	= "${base64encode(tls_private_key.installkey.private_key_pem)}"
}

output "registry_ca_cert"{
  value = "${module.gather_output.registry_ca_cert}"
} 

output "icp_install_dir"{
  value = "${module.gather_output.icp_install_dir}"
} 

output "registry_config_do_name"{
	value = "${var.deployment}${random_id.clusterid.hex}RegistryConfig"
}
