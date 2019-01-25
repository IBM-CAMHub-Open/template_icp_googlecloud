# Terraform ICP Google Cloud

This Terraform example uses the [Google Cloud  provider](https://www.terraform.io/docs/providers/google/index.html) to provision virtual machines on Google Cloud and [Terraform Module ICP Deploy](https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy) to prepare VSIs and deploy [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/) version 3.1.0 or later.  This Terraform template automates best practices learned from installing ICP on Google Cloud Infrastructure.

## Deployment overview
This template creates an environment where
 - Cluster is deployed directly on public network and is accessed on the VMs public IP using a [NAT Gateway](https://cloud.google.com/nat/docs/overview)
 - There are no load balancers, but applications can be accessed via NodePort on public IP of proxy node
 - Most ICP services are disabled (some can be activated via `terraform.tfvars` settings as described below)
 - Minimal VM sizes ( the size can be changes at deployment time )
 - No separate boot node
 - One Master node only. The Master node has also the role of the Boot node so only one Master vm can be deployed in this configuration.
 - No Vulnerability Advisor node and vulnerability advisor service disabled by default
 - The number of the Management, Worker and Proxy nodes can be specified at deployment time.
 Note : If the number of Management, Worker and Proxy are set to zero, the Master vm will take the role of the Worker, Management and Proxy node respectively.
 - You cannot deploy more than one Proxy node since there is no load balancer defined. 

## Architecture Diagram

![Architecture](../../static/icp_ce_minimal.png)

## Pre-requisites

* Working copy of [Terraform](https://www.terraform.io/intro/getting-started/install.html)
  * As of this writing, IBM Cloud Terraform provider is not in the main Terraform repository and must be installed manually.  See [these steps](https://ibm-cloud.github.io/tf-ibm-docs/index.html#using-terraform-with-the-ibm-cloud-provider).  The templates have been tested with Terraform version 0.11.7 and the IBM Cloud provider version 0.11.3.
* The template is tested on VSIs based on Ubuntu 16.04.  RHEL is not supported in this automation.


### Using the Terraform templates

1. git clone the repository

1. Navigate to the template directory `templates/icp-minimal`

1. Create a `terraform.tfvars` file to reflect your environment.  Please see [variables.tf](variables.tf) and below tables for variable names and descriptions.  Here is an example `terraform.tfvars` file:


1. Run `terraform init` to download depenencies (modules and plugins)

1. Run `terraform plan` to investigate deployment plan

1. Run `terraform apply` to start deployment.


### Automation Notes

#### What does the automation do
1. Create the virtual machines as defined in `variables.tf` and `terraform.tfvars`
   - Use cloud-init to add a user `icpdeploy` with a randomly generated ssh-key
   - Configure a separate hard disk to be used by docker
   - Deploys the ICP binaries and the Docker image, if specified. Unzips and loads the ICP image into the docker repository.
2. Create security groups and rules for cluster communication as declared in [security_group.tf](security_group.tf)
3. Handover to the [icp-deploy](https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy) terraform module as declared in the [icp-deploy.tf](icp-deploy.tf) file

#### What does the icp deploy module do
1. It uses the provided ssh key which has been generated for the `icpdeploy` user to ssh from the terraform controller to all cluster nodes to install ICP prerequisites
2. It generates a new ssh keypair for ICP Boot(master) node to ICP cluster communication and distributes the public key to the cluster nodes. This key is used by the ICP Ansible installer.
3. It populates the necessary `/etc/hosts` file on the boot node
4. It generates the ICP cluster hosts file based on information provided in [icp-deploy.tf](icp-deploy.tf)
5. It generates the ICP cluster `config.yaml` file based on information provided in [icp-deploy.tf](icp-deploy.tf)

#### Security Groups

The automation leverages Security Groups to lock down public and private access to the cluster.

- SSH is allowed to all cluster nodes to ease exploration and investigation
- UDP and TCP port 30000 - 32767 are allowed on proxy node to enable use of [NodePort](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/manage_applications/expose_app.html)
- Inbound communication to the master node is permitted on [ports relevant to the ICP service](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/supported_system_config/required_ports.html)
- All outbound communication is allowed.
- All other communication is only permitted between cluster nodes.

### Terraform configuration

Please see [variables.tf](variables.tf) for additional parameters.

| name | required                        | value        |
|----------------|------------|--------------|
| `ssh_user`   | yes          | Username for IBM Cloud infrastructure account |
| `region`   | yes           | The region the resource should be created in. |
| `zone`   | yes           | The region zone the resource should be created in. |
| `image_type`   | yes           | The OS project and family to install on the VSIs. Only Ubuntu 16.04 was tested. |
| `icp_inception_image` | yes | ICP image to use for installation, for example ibmcom/icp-inception-amd64:3.1.1-ee |
| `docker_package_location` | no | URI for docker package location, e.g. http://<myhost>/icp-docker-17.09_x86_64.bin. If not specified and using Ubuntu, will install latest `docker-ce` off public repo. |
| `image_location` | yes | URI for image package location, e.g. http://<myhost>/ibm-cloud-private-x86_64-3.1.1.tar.gz |
| `icppassword` | no | ICP administrator password.  One will be generated if not set. |
| `deployment` | no | Identifier prefix added to the host names of all your infrastructure resources for organising/naming ease | `network_interface` | yes | IBM Cloud Private Proxy Network Interface | ens4

### Master Node Input Settings

| Name | Description | Type | Default |
|------|-------------|:----:|:-----:|
| nodes | Master number of nodes | int | `1` |
| memory | Master Node Memory Allocation (mb) | string | `32768` |
| cpu | Master Node vCPU Allocation | string | `12` |
| disk_size | Master Node Boot Disk Size (GB)  | int | `300` |
| docker_vol_size | Master Nodes Docker Disk size (GB) | int | `100` |

### Proxy Node Input Settings

| Name | Description | Type | Default |
|------|-------------|:----:|:-----:|
| nodes | Proxy number of nodes. If set to 0, the Master Node becomes Proxy node too. | int | `0` | 
| memory | Proxy Node Memory Allocation (mb) | string | `4096` |
| cpu | Proxy Node vCPU Allocation | string | `4` |
| disk_size | Proxy Node Boot Disk Size (GB)  | int | `100` |
| docker_vol_size | Proxy Nodes Docker Disk size (GB) | int | `100` |

### Management Nodes Input Settings

| Name | Description | Type | Default |
|------|-------------|:----:|:-----:|
| nodes | Management number of nodes. If set to 0, the Master Node becomes Management node too. | int | `0` | 
| memory | Management Node Memory Allocation (mb) | string | `16384` |
| cpu | Management Node vCPU Allocation | string | `4` |
| disk_size | Management Node Boot Disk Size (GB)  | int | `100` |
| docker_vol_size | Management Nodes Docker Disk size (GB) | int | `100` |

### Worker Nodes Input Settings

| Name | Description | Type | Default |
|------|-------------|:----:|:-----:|
| nodes | Worker number of nodes. If set to 0, the Master Node becomes Worker node too. | int | `0` | 
| memory | Worker Node Memory Allocation (mb) | string | `16384` |
| cpu | Worker Node vCPU Allocation | string | `4` |
| disk_size | Worker Node Boot Disk Size (GB)  | int | `100` |
| docker_vol_size | Worker Nodes Docker Disk size (GB) | int | `100` |
