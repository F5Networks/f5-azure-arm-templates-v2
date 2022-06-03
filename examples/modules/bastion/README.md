
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

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details.

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| adminUsername | No | "azureuser" | string | User name for the Virtual Machine. |
| cloudInitUrl | No |  | string | URI to cloud-init config. |
| createAutoscaleGroup | No | true | boolean | Choose true to create the bastion instances in an autoscaling configuration. |
| instanceName | No | "vm01" | string | Name of the Virtual Machine. |
| instanceType | No | "Standard_D2_v4" | string | Enter valid instance type. |
| nsgId | No |  | string | Private NSG ID for the Virtual Machine. |
| publicIpId | Yes |  | string | Public IP ID for the Virtual Machine. |
| sshKey | Yes |  | string | Supply the SSH public key you want to use to connect to the bastion instance. |
| subnetId | Yes |  | string | Private subnet ID for the Virtual Machine. |
| tagValues | No | "application": "APP", "cost": "COST", "environment": "ENV", "group": "GROUP", "owner": "OWNER" | object | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique, adjust them as needed for each key. |
| vmScaleSetMaxCount | Yes | 10 | integer | The maximum number of bastion instances that can be deployed into the Virtual Machine Scale Set. |
| vmScaleSetMinCount | Yes | 1 | integer | The minimum (and default) number of bastion instances that will be deployed into the Virtual Machine Scale Set. |

### Template Outputs

| Name | Required Resource | Type | Description |
| --- | --- | --- | --- |
| resourceGroup | Virtual Machine Scale Set | string | Virtual Machine Scale Set Resource Group. |
| vmName | Virtual Machine | string | Virtual Machine Name. |
| vmssId | Virtual Machine Scale Set | string | Virtual Machine Scale Set Resource ID. |
| vmssName | Virtual Machine Scale Set | string | Virtual Machine Scale Set Name. |
