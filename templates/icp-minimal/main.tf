provider "google" {
  version = "~> 1.5"
}
/*
provider "google-beta" {
}
*/
locals {
   icppassword    = "${var.icppassword != "" ? "${var.icppassword}" : "P${random_id.adminpassword.hex}@p"}"

  registry_server = "${var.registry_server != "" ? "${var.registry_server}" : "" }" 
  namespace       = "${dirname(var.icp_inception_image)}" # This will typically return ibmcom
  
  icp-version = "${var.icp_inception_image}"
  image_repo=""
  /*
  # The final image repo will be either interpolated from what supplied in icp_inception_image or
  image_repo      = "${var.registry_server == "" ? dirname(var.icp_inception_image) : "${local.registry_server}/${local.namespace}"}"
  icp-version     = "${format("%s%s%s", "${local.docker_username != "" ? "${local.docker_username}:${local.docker_password}@" : ""}",
                      "${var.registry_server != "" ? "${var.registry_server}/" : ""}",
                      "${var.icp_inception_image}")}"
  */

  # If we're using external registry we need to be supplied registry_username and registry_password
  docker_username = "${var.registry_username != "" ? var.registry_username : "admin"}"
  docker_password = "${var.registry_password != "" ? var.registry_password : "${local.icppassword}"}"
 
  docker_package_uri = "${var.docker_package_location != "" ? "/tmp/${basename(var.docker_package_location)}" : "" }"
  # If we're using external registry we need to be supplied registry_username and registry_password
  #docker_username = "${var.ssh_user}"
  #docker_password = "${local.icppassword}"


    # This is just to have a long list of disabled items to use in icp-deploy.tf
    disabled_list = "${list("disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled","disabled")}"

    disabled_management_services = "${zipmap(var.disabled_management_services, slice(local.disabled_list, 0, length(var.disabled_management_services)))}"

    is_311 = "${replace(var.icp_inception_image, "3.1.1", "") != var.icp_inception_image ? "true" : "false"}"

}

# Create a unique random clusterid for this cluster
resource "random_id" "clusterid" {
  byte_length = "4"
}

# Create a SSH key for SSH communication from terraform to VMs
resource "tls_private_key" "installkey" {
  algorithm   = "RSA"
}

# Generate a random string in case user wants us to generate admin password
resource "random_id" "adminpassword" {
  byte_length = "16"
}
