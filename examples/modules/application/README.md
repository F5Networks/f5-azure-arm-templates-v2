
# Deploying Application Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)

## Contents

- [Deploying Application Template](#deploying-application-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)

## Introduction

This template deploys a simple example application. It launches a linux VM used for hosting applications and can be customized to deploy your own startup script:

1) [Cloud-init](https://cloudinit.readthedocs.io/en/latest/)
2) Bash script


## Prerequisites

- Requires existing network infrastructure and subnet
- Accept any Marketplace "License/Terms and Conditions" for the [image](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/canonical.0001-com-ubuntu-server-focal?tab=Overview) used for the application. For more information, see Azure [documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage#deploy-an-image-with-marketplace-terms).

## Important Configuration Notes

- Public IPs won't be provisioned for this template.
- This template downloads and renders custom configs (i.e. cloud-init or bash script) as external files and therefore, the custom configs must be reachable from the Virtual Machine (i.e. routing to any remotely hosted files must be provided for outside of this template).
- Examples of custom configs are provided under scripts directory.
- This template uses the Linux Ubuntu Server 20.04 LTS as Virtual Machine operational system.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| vnetName | Yes | Virtual Network name. |
| vnetResourceGroupName | Yes | Azure Resource Group used for scoping resources. |
| subnetName | Yes | Private subnet name for the Virtual Machine. |
| appPrivateAddress | Yes | Desire private IP; must be within private subnet. |
| adminUsername | Yes | User name for the Virtual Machine. |
| adminPassword | Yes | Password for the Virtual Machine. |
| dnsLabel | Yes | Unique DNS Name for the Public IP address used to access the Virtual Machine. |
| instanceName | Yes | Name of the Virtual Machine. |
| instanceType | Yes | Instance size of the Virtual Machine. |
| initScriptDeliveryLocation | No | URI to bash init script. |
| initScriptParameters | No | Parameters used for init script; multiple parameters must be provided as a space-separated string. |
| cloudInitDeliveryLocation | No | URI to cloud-init config. |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| appIp | Virtual Machine private IP address | Virtual Machine | string |
