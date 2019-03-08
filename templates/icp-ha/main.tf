provider "google" {
  version = "~> 1.5"
}

locals {
   icppassword    = "${var.icppassword != "" ? "${var.icppassword}" : "P${random_id.adminpassword.hex}@p"}"
/*
  registry_server = "${var.registry_server != "" ? "${var.registry_server}" : "" }" 
  namespace       = "${dirname(var.icp_inception_image)}" # This will typically return ibmcom
  
  #icp-version = "${var.icp_inception_image}"
  #image_repo=""
  
  # The final image repo will be either interpolated from what supplied in icp_inception_image or
  image_repo      = "${var.registry_server == "" ? dirname(var.icp_inception_image) : "${local.registry_server}/${local.namespace}"}"
*/
  /*
  icp-version     = "${format("%s%s%s", "${local.docker_username != "" ? "${local.docker_username}:${local.docker_password}@" : ""}",
                      "${var.registry_server != "" ? "${var.registry_server}/" : ""}",
                      "${var.icp_inception_image}")}"
  */

  # If we're using external registry we need to be supplied registry_username and registry_password
  docker_username = "${var.registry_username != "" ? var.registry_username : "admin"}"
  docker_password = "${var.registry_password != "" ? var.registry_password : "${local.icppassword}"}"

  registry_server = "${var.deployment}-boot-${random_id.clusterid.hex}"
  namespace       = "${dirname(var.icp_inception_image)}" # This will typically return ibmcom
  image_repo      = "${var.image_location == "" ? dirname(var.icp_inception_image) : "${local.registry_server}:8500/${local.namespace}"}"

  # Intermediate interpolations
  credentials = "${var.registry_username != "" ? join(":", list("${var.registry_username}"), list("${var.registry_password}")) : ""}"
  cred_reg   = "${local.credentials != "" ? join("@", list("${local.credentials}"), list("${local.registry_server}")) : ""}"

  # Inception image formatted for ICP deploy module
  inception_image = "${local.cred_reg != "" ? join("/", list("${local.cred_reg}"), list("${var.icp_inception_image}")) : var.icp_inception_image}"
  icp-version = "${local.inception_image}"
  
  docker_package_uri = "${var.docker_package_location != "" ? "/tmp/${basename(var.docker_package_location)}" : "" }"


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

# Create certificates for secure docker registry
# Needed if we are supplied a tarball.
resource "tls_private_key" "registry_key" {
  algorithm = "RSA"
  rsa_bits = "4096"
}

resource "tls_self_signed_cert" "registry_cert" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.registry_key.private_key_pem}"

  subject {
    common_name  = "${local.registry_server}"
  }

  dns_names  = ["${local.registry_server}"]
  validity_period_hours = "${24 * 365 * 10}"

  allowed_uses = [
    "server_auth"
  ]
}

