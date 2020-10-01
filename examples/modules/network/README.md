
# Deploying Network Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)

## Contents

- [Deploying Network Template](#deploying-network-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)

## Introduction

This ARM template creates virtual network, subnets, and security groups required to support F5 solutions. Link this template to create networks, security groups, and subnets required for F5 deployments.

## Prerequisites

 - None
 
## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add network.json as a linked template into your templated solution.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| mgmtNsg | Yes | Valid values: 'Default', 'None', existing_nsg_name. 'Default' creates a network security group named 'mgmtNSG' and applies SG to mgmtSubnet. 'None', does not create a management security group, or apply group to mgmtSubnet. Supplying an existing security group name will apply SG to 'mgmtSubnet'. |
| appNsg | Yes | Valid values: 'Default', 'None', existing_nsg_name. 'Default' creates a network security group named 'appNSG' and applies SG to appSubnet. 'None', does not create a management security group, or apply group to appSubnet. Supplying an existing security group name will apply SG to 'appSubnet'. |
| restrictedSrcMgmtAddress | Yes | Address range allowed to access BIG-IP management. Used to construct rules for mgmtNSG security group. |
| restrictedSrcMgmtPort | Yes | F5 admin portal port used to access BIG-IP management. Used to construct rules for mgmtNSG security group. |
| provisionPublicIP | Yes | Used to construct appNsg. 'false' creates a rule to block internet traffic. 'true', creates a rule to allow internet traffic.  |
| virtualNetworkName| Yes | Name used to create virtual network. |
| vnetAddressPrefix | Yes | Enter the start of the CIDR block used when creating the Vnet and subnets.  You MUST type just the first two octets of the /16 virtual network that will be created, for example '10.0', '10.100', 192.168'." |
| numSubnets| Yes | Number of subnets to create. Value of >=1 creates subnet named mgmtSubnet. Value >=2 creates 2 subnets named mgmtSubnet and appSubnet. Value > 2 creates mgmtSubnet, appSubnet, and subnet(n) where n starts at 2 and continues to *supplied value*-2. Subnet values are constructed using vnetAddressPrefix.*n*.0/24 where *n=0* for mgmtSubnet, *n=1* for appSubnet, and *n* increments by one for each additional subnet created. |
| tagValues| Yes | List of tags to add to created resources. |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| appNSG | Application Network Security Group resource ID | Application Network Security Group | string |
| appSubnet | Application Subnet resource ID | Application Subnet | string |
| mgmtNSG | Management Network Security Group resource ID | Management Network Security Group | string |
| mgmtSubnet | Management Subnet resource ID | Management Subnet | string |
| subnets | Application Subnets resource IDs | Application Subnets | array |
| virtualNetwork | Virtual Network resource ID | Virtual Network | string |


## Resource Creation Flow Chart

![Resource Creation Flow Chart](https://github.com/F5Networks/f5-azure-arm-templates-v2/blob/master/examples/images/azure-network-module.png)
