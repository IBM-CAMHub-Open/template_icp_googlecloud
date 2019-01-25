<!---
Copyright IBM Corp. 2019, 2019
--->

# Terraform ICP Google Cloud

This repository contains a collection of Terraform templates. The Terraform example configurations uses the [Google Cloud  provider](https://www.terraform.io/docs/providers/google/) to provision virtual machines on Google Cloud Infrastructure Platform
and [Terraform Module ICP Deploy](https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy) to prepare VSIs and deploy [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/) on them. These Terraform templates automate best practices learned from installing ICP on Google Cloud Infrastructure.

## Pre-requisites

* Working copy of [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* Select a template that most closely matches your desired target environment from the [available templates](templates)


## Selecting the right template

We currently have three templates available

- [icp-ce-minimal](templates/icp-ce-minimal)
  * This template will deploy ICP Community Edition with a minimal amount of Virtual Machines and a minimal amount of services enabled
  *  Additional ICP services such as logging, monitoring and istio can be enabled as well as dedicated management nodes can be added with minor configuration changes
  * This template is suitable for a quick view of basic ICP and Kubernetes functionality, and simple PoCs and verifications

- [icp-ce-with-loadbalancers](templates/icp-ce-with-loadbalancers)
  * Like the `icp-ce-minimal` template, this will deploy a minimal environment, but in this template Loadbalancers will also be created. This creates a topology more similar to the `icp-ee` environment, where external loadbalancers are a central part of the network design, but with less services and resources active
  *  This template is suitable for validation tests and PoCs where external loadbalancer functionality is required

- [icp-ee](templates/icp-ee)
  * This template deploys a more robust environment, with control plane in a high availabilty configuration
  * By default a separate boot node is provisioned and all SSH communication goes through this
  * This configuration requires access to ICP Enterprise Edition, typically supplied as a tarball


Follow the link to these templates for more detailed information about them.
