
# Deploying Bastion Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)

## Contents

- [Deploying Bastion Template](#deploying-bastion-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)

## Introduction

This template deploys a simple example bastion host. It launches a linux VM used for bastion host and can be customized to deploy your own startup script:

1) [Cloud-init](https://cloudinit.readthedocs.io/en/latest/)
2) Bash script


## Prerequisites

- Requires existing network infrastructure and subnet.
- Accept any Marketplace "License/Terms and Conditions" for the [image](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/canonical.0001-com-ubuntu-server-focal?tab=Overview) used for the bastion. For more information, see Azure [documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage#deploy-an-image-with-marketplace-terms).

## Important Configuration Notes

- This template downloads and renders custom configs (i.e. cloud-init or bash script) as external files and therefore, the custom configs must be reachable from the Virtual Machine (i.e. routing to any remotely hosted files must be provided for outside of this template).
- Examples of custom configs are provided under scripts directory.
- This template uses the Linux Ubuntu Server 20.04 LTS as Virtual Machine operational system.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| adminUsername | No | User name for the Virtual Machine. |
| cloudInitUrl | No | URI to cloud-init config. |
| createAutoscaleGroup | No | Choose true to create the bastion instances in an autoscaling configuration. |
| instanceName | No | Name of the Virtual Machine. |
| instanceType | No | Enter valid instance type. |
| nsgId | No | Private NSG ID for the Virtual Machine. |
| sshKey | Yes | Supply the SSH public key you want to use to connect to the bastion instance. |
| subnetId | Yes | Private subnet ID for the Virtual Machine. |
| publicIpId | Yes | Public IP ID for the Virtual Machine. |
| tagValues | No | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique, adjust them as needed for each key. |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| resourceGroup | Virtual Machine Scale Set Resource Group | Virtual Machine Scale Set | string |
| vmName | Virtual Machine Name | Virtual Machine | string |
| vmssId | Virtual Machine Scale Set resource ID | Virtual Machine Scale Set | string |
| vmssName | Virtual Machine Scale Set Name | Virtual Machine Scale Set | string |
