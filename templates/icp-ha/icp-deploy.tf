

resource "null_resource" "image_copy" {

  triggers {
    imageversion = "${var.image_location}"
  }

  connection {

    host     = "${google_compute_instance.icp-boot.network_interface.0.network_ip}"
    bastion_host  = "${google_compute_instance.icp-boot.network_interface.0.access_config.0.nat_ip}"

    user          = "${var.ssh_user}"
    private_key   = "${tls_private_key.installkey.private_key_pem}"
  }  
  provisioner "remote-exec" {

    # We need to wait for cloud init to finish it's boot sequence.
    inline = [
      "echo \"${google_compute_address.icp-master.address} ${var.deployment}-cluster.icp\" | sudo tee -a /etc/hosts",    
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "/opt/ibm/scripts/download_icp.sh ${var.image_location != "" ? "-i ${var.image_location}" : ""} -u ${var.download_user} -p ${var.download_user_password}"
    ]
  }  
}

resource "null_resource" "image_load" {
  # Only do an image load if we have provided a location. Presumably if not we'll be loading from private registry server
  depends_on = ["null_resource.image_copy"]

  triggers {
    imageversion = "${var.image_location}"
  }

  connection {
  
    host     = "${google_compute_instance.icp-boot.network_interface.0.network_ip}"
    bastion_host  = "${google_compute_instance.icp-boot.network_interface.0.access_config.0.nat_ip}"
  
    user          = "${var.ssh_user}"
    private_key   = "${tls_private_key.installkey.private_key_pem}"
  }

  provisioner "remote-exec" {

    # We need to wait for cloud init to finish it's boot sequence.
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "export REGISTRY_USERNAME=${local.docker_username}",
      "export REGISTRY_PASSWORD=${local.docker_password}",
      "/opt/ibm/scripts/load_image.sh -u ${local.docker_username} -c ${local.docker_password} -p ${var.image_location} ${local.registry_server != "" ? "-r ${local.registry_server}" : ""}",
      "sudo touch /opt/ibm/.imageload_complete"
    ]
  }
}

##################################
### Deploy ICP to cluster
##################################
module "icpprovision" {

  source = "git::https://github.com/IBM-CAMHub-Open/template_icp_modules.git?ref=3.2.1//public_cloud"
  
    # Provide IP addresses for boot, master, mgmt, va, proxy and workers
    boot-node     = "${google_compute_instance.icp-boot.network_interface.0.network_ip}"
    bastion_host  = "${google_compute_instance.icp-boot.network_interface.0.access_config.0.nat_ip}"

    image_load_finished = true

    #in support of version upgrade
    icp-version-upgrade = "${local.icp-version}"
    image-location-upgrade = "${var.image_location}"

    #in support of workers scaling
 	icp-worker = "${slice(concat(google_compute_instance.icp-worker.*.network_interface.0.network_ip,
                                     google_compute_instance.icp-master.*.network_interface.0.network_ip),
                              var.worker["nodes"] > 0 ? 0 : length(google_compute_instance.icp-worker.*.network_interface.0.network_ip),
                              var.worker["nodes"] > 0 ? length(google_compute_instance.icp-worker.*.network_interface.0.network_ip) :
                                                      length(google_compute_instance.icp-worker.*.network_interface.0.network_ip) +
                                                        length(google_compute_instance.icp-master.*.network_interface.0.network_ip))}"
                                                        
    icp-host-groups = {
        master = ["${google_compute_instance.icp-master.*.network_interface.0.network_ip}"]
        proxy = "${slice(concat(google_compute_instance.icp-proxy.*.network_interface.0.network_ip,
                                google_compute_instance.icp-master.*.network_interface.0.network_ip),
                         var.proxy["nodes"] > 0 ? 0 : length(google_compute_instance.icp-proxy.*.network_interface.0.network_ip),
                         var.proxy["nodes"] > 0 ? length(google_compute_instance.icp-proxy.*.network_interface.0.network_ip) :
                                                  length(google_compute_instance.icp-proxy.*.network_interface.0.network_ip) +
                                                    length(google_compute_instance.icp-master.*.network_interface.0.network_ip))}"
        worker = "${slice(concat(google_compute_instance.icp-worker.*.network_interface.0.network_ip,
                                     google_compute_instance.icp-master.*.network_interface.0.network_ip),
                              var.worker["nodes"] > 0 ? 0 : length(google_compute_instance.icp-worker.*.network_interface.0.network_ip),
                              var.worker["nodes"] > 0 ? length(google_compute_instance.icp-worker.*.network_interface.0.network_ip) :
                                                      length(google_compute_instance.icp-worker.*.network_interface.0.network_ip) +
                                                        length(google_compute_instance.icp-master.*.network_interface.0.network_ip))}"
        


        management = "${slice(concat(google_compute_instance.icp-mgmt.*.network_interface.0.network_ip,
                                     google_compute_instance.icp-master.*.network_interface.0.network_ip),
                              var.mgmt["nodes"] > 0 ? 0 : length(google_compute_instance.icp-mgmt.*.network_interface.0.network_ip),
                              var.mgmt["nodes"] > 0 ? length(google_compute_instance.icp-mgmt.*.network_interface.0.network_ip) :
                                                      length(google_compute_instance.icp-mgmt.*.network_interface.0.network_ip) +
                                                        length(google_compute_instance.icp-master.*.network_interface.0.network_ip))}"
        
        va = ["${google_compute_instance.icp-va.*.network_interface.0.network_ip}"]
    
    }



    # Provide desired ICP version to provision
    icp-version = "${local.icp-version}"
    icp_config_file = "${path.module}/scripts/config.yaml"

    /* Workaround for terraform issue #10857
     When this is fixed, we can work this out automatically */
    cluster_size  = "${1 + var.master["nodes"] + var.worker["nodes"] + var.proxy["nodes"] + var.mgmt["nodes"] + var.va["nodes"]}"

    ###################################################################################################################################
    ## You can feed in arbitrary configuration items in the icp_configuration map.
    ## Available configuration items availble from https://www.ibm.com/support/knowledgecenter/SSBS6K_3.1.0/installing/config_yaml.html
    icp_configuration = {
      "network_cidr"                    = "${var.pod_network_cidr}"
      "service_cluster_ip_range"        = "${var.service_network_cidr}"
      "cluster_lb_address"              = "${google_compute_address.icp-master.address}"
      "proxy_lb_address"                = "${google_compute_address.icp-proxy.address}"
      
      "cluster_CA_domain"               = "${var.deployment}-cluster.icp"      
      "cluster_name"                    = "${var.deployment}"

      #"cloud_provider"                  = "gce"
      #"kubelet_nodename"                = "hostname"

      #"calico_ipip_enabled"             = "false" # shut off ipip since we've added the pod network as secondary
      "calico_ip_autodetection_method"  = "interface=${var.network_interface}"

      # An admin password will be generated if not supplied in terraform.tfvars
      "default_admin_password"          = "${local.icppassword}"

      # This is the list of disabled management services
      "management_services"             = "${local.disabled_management_services}"

      #"image_repo"                      = "${local.image_repo}" # Will either be our private repo or external repo
      "docker_username"                 = "${local.docker_username}" # Will either be username generated by us or supplied by user
      "docker_password"                 = "${local.docker_password}" # Will either be username generated by us or supplied by user
    
    }

    # We will let terraform generate a new ssh keypair
    # for boot master to communicate with worker and proxy nodes
    # during ICP deployment
    generate_key = true

    # SSH user and key for terraform to connect to newly created VMs
    # ssh_key is the private key corresponding to the public assumed to be included in the template
    ssh_user        = "${var.ssh_user}"
    ssh_key_base64  = "${base64encode(tls_private_key.installkey.private_key_pem)}"
    ssh_agent       = false

    # Make sure to wait for image load to complete
     hooks = {
      "boot-preconfig" = [
        "while [ ! -f /opt/ibm/.imageload_complete ]; do sleep 5; done"
      ]
       "postinstall" = [
         "/opt/ibm/scripts/copy_certif.sh"
       ] 
    }

}
