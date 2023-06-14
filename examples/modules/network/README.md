
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

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details.

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| createNatGateway | No | false | boolean | You must select Yes to create a NAT gateway to allow outbound access when deploying a standalone BIG-IP VE without a public management IP address. Note: The NAT gateway is applied to subnet0. |
| numSubnets| No | 1 | integer | Number of subnets to create. A route table resource will be created and associated with each subnet resource. |
| tagValues| No | {"application": "f5demoapp", "cost": "f5cost", "environment": "f5env", "group": "f5group", "owner": "f5owner"}, | object | List of tags to add to created resources. |
| vnetAddressPrefix | No | 10.0 | string | Enter the start of the CIDR block used when creating the Vnet and subnets. You MUST type just the first two octets of the /16 virtual network that will be created, for example '10.0', '10.100', 192.168'." |
| vnetName| No | "virtualNetwork" | string | Name used to create virtual network. |

### Template Outputs

| Name | Required Resource | Type | Description |
| --- | --- | --- | --- |
| natGateway | NAT Gateway | string | NAT Gateway resource ID. |
| routeTables | Route Tables | array | Route tables resource IDs. |
| subnets | Subnets | array | Subnets resource IDs. |
| virtualNetwork | Virtual Network | string | Virtual Network resource ID. |


## Resource Creation Flow Chart

![Resource Creation Flow Chart](https://github.com/F5Networks/f5-azure-arm-templates-v2/blob/v2.8.0.0/examples/images/azure-network-module.png)
