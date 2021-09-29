
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

This ARM template creates a virtual network, subnets, and route tables required to support F5 solutions. Link this template to create networks, subnets, and route tables required for F5 deployments.

## Prerequisites

 - None
 
## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add network.json as a linked template into your templated solution.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| createNatGateway | No | You must select Yes to create a NAT gateway to allow outbound access when deploying a standalone BIG-IP VE without a public management IP address. Note: The NAT gateway is applied to subnet0. |
| numSubnets| No | Number of subnets to create. A route table resource will be created and associated with each subnet resource. |
| tagValues| No | List of tags to add to created resources. |
| vnetAddressPrefix | No | Enter the start of the CIDR block used when creating the Vnet and subnets. You MUST type just the first two octets of the /16 virtual network that will be created, for example '10.0', '10.100', 192.168'." |
| vnetName| No | Name used to create virtual network. |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| natGateway | NAT Gateway resource ID | NAT Gateway | string |
| routeTables | Route tables resource IDs | Route Tables | array |
| subnets | Subnets resource IDs | Subnets | array |
| virtualNetwork | Virtual Network resource ID | Virtual Network | string |


## Resource Creation Flow Chart

![Resource Creation Flow Chart](https://github.com/F5Networks/f5-azure-arm-templates-v2/blob/v1.4.0.0/examples/images/azure-network-module.png)
