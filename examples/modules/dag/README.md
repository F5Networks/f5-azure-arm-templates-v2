
# Deploying Dag/Ingress Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)


## Contents

- [Deploying Dag/Ingress Template](#deploying-dagingress-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)

## Introduction

This template creates various cloud resources to get traffic to BIG-IP solutions, including; Public IPs (for accessing management and dataplane/VIP addresses), load balancers (for example, a standard sku external load balancer and/or a standard SKU internal load balancer) to distribute or disaggregate traffic, and network security groups, etc.

## Prerequisites

 - Existing subnet required for internal load balancer creation.
 
## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add a template as a linked template into your templated solution.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| numberPublicMgmtIPAddresses | Yes | Valid values include any integer between 1-10. Enter the number of public mgmt IP addresses to create. |
| numberPublicExternalIPAddresses | Yes | Valid values include any integer between 1-10. Enter the number of public external IP addresses to create. At least one is required to build ELB. |
| dnsLabel | Yes | Unique DNS Name for the Public IP address used to access the Virtual Machine. |
| externalLoadBalancerName | Yes | Valid values include 'None', or an external load balancer name. A value of 'None' will not create an external load balancer. Specifying a name creates an external load balancer with the name specified. |
| loadBalancerRulePorts | Yes | Valid values include valid TCP ports. Enter an array of ports that your applications use. For example: '[80,443,445]' |
| internalLoadBalancerName | Yes | Valid values include 'None', or an internal load balancer name. A value of 'None' will not create an internal load balancer. Specifying a name creates an internal load balancer with the name specified. |
| internalSubnetId | Yes | Enter the subnet ID to use for frontend internal load balancer configuration. If you specify 'None' for provision internal load balancer, this setting has no effect. |
| internalLoadBalancerProbePort | Yes | Specify a TCP port for the internal load balancer to monitor. If you specify 'None' for provision internal load balancer, this setting has no effect. |
| nsg0 | Yes | Valid values include an array containing network security rule property objects, or an empty array. A non-empty array value creates a security group and inbound rules using the destinationPortRanges and sourceAddressPrefix values provided for each object. For example, this value will combine management and application security rules for 1NIC deployments: ```[{"destinationPortRanges": ["22","8443"],"sourceAddressPrefix": "1.2.3.4/32"},{"destinationPortRanges": ["80","443"],"sourceAddressPrefix": "*"}]``` |
| nsg1 | Yes | Valid values include an array containing network security rule property objects, or an empty array. A non-empty array value creates a security group and inbound rules using the destinationPortRanges and sourceAddressPrefix values provided for each object. For example, this example will allow traffic on ports 80 and 443 from all sources: ```[{"destinationPortRanges": ["80","443"],"sourceAddressPrefix": "*"}]``` By default, an outbound security rule is also applied to this network security group to allow traffic to an Azure load balancer. |
| nsg2 | Yes | Valid values include an array containing network security rule property objects, or an empty array. A non-empty array value creates a security group and inbound rules using the destinationPortRanges and sourceAddressPrefix values provided for each object. For example, this example will allow traffic on ports 80 and 443 from a specific IP address: ```[{"destinationPortRanges": ["80","443"],"sourceAddressPrefix": "1.2.3.4/32"}]``` By default, an outbound security rule is also applied to this network security group to allow traffic to an Azure load balancer. |
| tagValues| Yes | List of tags to add to created resources. |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| externalIpIds | External Public IP Address resource IDs | External Public IP Address | array |
| externalIps | External Public IP Addresses | External Public IP Address | array |
| externalBackEndLoadBalancerID | Application Back End Address Pool resource ID | External Load Balancer | string |
| externalBackEndMgmtLoadBalancerID | Management Back End Address Pool resource ID | External Load Balancer | string |
| externalFrontEndLoadBalancerID | Application Front End resource IDs | External Load Balancer | array |
| externalFrontEndMgmtLoadBalancerID | Management Front End resource ID | External Load Balancer | string |
| externalLoadBalancer | External Load Balancer resource ID | External Load Balancer | string |
| externalLoadBalancerProbesID | External Load Balancer Probe resource IDs | External Load Balancer | array |
| externalLoadBalancerRulesID | External Load Balancing Rules resource IDs | External Load Balancer | array |
| inboundMgmtNatPool | Management NAT Pool resource ID | Management Public IP Address | string |
| inboundSshNatPool | SSH NAT Pool resource ID | Management Public IP Address | string |
| internalBackEndLoadBalancerID | Internal Back End Address Pool resource ID | Internal Load Balancer | string |
| internalFrontEndLoadBalancerIP | Internal Front End resource ID | Internal Load Balancer | string |
| internalLoadBalancerProbeID | Internal Load Balancer Probe ID | Internal Load Balancer | string |
| internalLoadBalancer | Internal Load Balancer resource ID | Internal Load Balancer | string |
| mgmtIpIds | Management Public IP Address resource IDs | Management Public IP Address | array |
| mgmtIps | Management Public IP Addresses | Management Public IP Address | array |
| nsg0Id | Network Security Group resource ID | Network Security Group | string |
| nsg1Id | Network Security Group resource ID | Network Security Group | string |
| nsg2Id | Network Security Group resource ID | Network Security Group | string |


## Resource Creation Flow Chart

![Resource Creation Flow Chart](https://github.com/F5Networks/f5-azure-arm-templates-v2/blob/master/examples/images/azure-dag-module.png)
