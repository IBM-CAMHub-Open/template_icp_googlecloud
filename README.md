<!---
Copyright IBM Corp. 2019, 2019
--->

# Terraform ICP Google Cloud

This repository contains a collection of Terraform templates. These Terraform templates deploy on Google Cloud the [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/) version 3.1.1 in an HA or minimal configuration. 


## Templates

Terraform templates available:

- [icp-minimal](templates/icp-minimal)
  * This template will deploy ICP Community Edition with a minimal amount of Virtual Machines and a minimal amount of services enabled
  *  Additional ICP services such as logging, monitoring and istio can be enabled as well as dedicated management nodes can be added using deployment parameters
  * This template is suitable for a quick view of basic ICP and Kubernetes functionality, and simple PoCs and verifications

- [icp-ha](templates/icp-ha)
  * This template deploys a more robust environment, with control plane in a high availability configuration
  * By default a separate boot node is provisioned and all SSH communication goes through this
  * This configuration requires access to ICP Enterprise Edition, typically supplied as a tar 


Follow the link to these templates for more detailed information about them.
