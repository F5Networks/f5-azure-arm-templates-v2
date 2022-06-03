
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

This template creates various cloud resources to get traffic to BIG-IP solutions, including; Public IPs (for accessing management and dataplane/VIP addresses), load balancers (for example, a standard SKU external load balancer and/or a standard SKU internal load balancer) to distribute or disaggregate traffic, and network security groups, etc.

## Prerequisites

 - Existing subnet required for internal load balancer creation.
 
## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add a template as a linked template into your templated solution.


### Template Input Parameters

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details.

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| externalLoadBalancerName | No | "None" | string | Valid values include 'None', or an external load balancer name. A value of 'None' will not create an external load balancer. Specifying a name creates an external load balancer with the name specified. |
| internalLoadBalancerName | No | "None" | string | Valid values include 'None', or an internal load balancer name. A value of 'None' will not create an internal load balancer. Specifying a name creates an internal load balancer with the name specified. |
| internalSubnetId | No |  | string | Enter the subnet ID to use for frontend internal load balancer configuration. If you specify 'None' for provision internal load balancer, this setting has no effect. |
| loadBalancerRulePorts | No | "80", "443" | array | Valid values include valid TCP ports. Enter an array of ports that your applications use. For example: '[80,443,445]' |
| nsg0 | No | [{"destinationPortRanges": ["22","8443"],"sourceAddressPrefix": "", "protocol": "Tcp"},{"destinationPortRanges": ["80","443"],"sourceAddressPrefix": "","protocol": "Tcp"}], | array | Valid values include an array containing network security rule property objects, or an empty array. A non-empty array value creates a security group and inbound rules using the destinationPortRanges, sourceAddressPrefix, and protocol values provided for each object. For example, this value will combine management and application security rules for 1NIC deployments: ```[{"destinationPortRanges": ["22","8443"],"sourceAddressPrefix": "1.2.3.4/32", "protocol": "Tcp"},{"destinationPortRanges": ["80","443"],"sourceAddressPrefix": "*", "protocol": "Tcp"}]``` |
| nsg1 | No | [{"destinationPortRanges": ["80","443"], "protocol": "Tcp" "sourceAddressPrefix": ""}] | array | Valid values include an array containing network security rule property objects, or an empty array. A non-empty array value creates a security group and inbound rules using the destinationPortRanges, sourceAddressPrefix, and protocol values provided for each object. For example, this example will allow traffic on ports 80 and 443 from all sources: ```[{"destinationPortRanges": ["80","443"],"sourceAddressPrefix": "*", "protocol": "Tcp"}]``` By default, an outbound security rule is also applied to this network security group to allow traffic to an Azure load balancer. |
| nsg2 | No |  [{"destinationPortRanges": ["80","443"], "protocol": "Tcp", "sourceAddressPrefix": ""}] | array | Valid values include an array containing network security rule property objects, or an empty array. A non-empty array value creates a security group and inbound rules using the destinationPortRanges, sourceAddressPrefix, and protocol values provided for each object. For example, this example will allow traffic on ports 80 and 443 from a specific IP address: ```[{"destinationPortRanges": ["80","443"],"sourceAddressPrefix": "1.2.3.4/32", "protocol": "Tcp"}]``` By default, an outbound security rule is also applied to this network security group to allow traffic to an Azure load balancer. |
| numberPublicExternalIpAddresses | No | 1 | integer | Valid values include any integer between 1-10. Enter the number of public external IP addresses to create. At least one is required to build ELB. |
| numberPublicMgmtIpAddresses | No | 0 | integer | Valid values include any integer between 1-10. Enter the number of public mgmt IP addresses to create. |
| tagValues| No | -"application": "APP", "cost": "COST", "environment": "ENV", "group": "GROUP", "owner": "OWNER" | object | List of tags to add to created resources. |
| uniqueString | Yes |  | string | A prefix that will be used to name template resources. Because some resources require globally unique names, we recommend using a unique value. |

### Template Outputs

| Name | Required Resource | Type | Description |
| --- | --- | --- | --- |
| externalBackEndLoadBalancerId | External Load Balancer | string | Application Back End Address Pool resource ID. |
| externalBackEndMgmtLoadBalancerId | External Load Balancer | string | Management Back End Address Pool resource ID. |
| externalFrontEndLoadBalancerId | External Load Balancer | array | Application Front End resource IDs. |
| externalFrontEndMgmtLoadBalancerId | External Load Balancer | string | Management Front End resource ID. | External Load Balancer |
| externalIpDns | External Public IP Address | array | External Public IP Addresses DNS. |
| externalIpIds | External Public IP Address | array | External Public IP Address resource IDs. |
| externalIps | External Public IP Address | array | External Public IP Addresses. |
| externalLoadBalancer | External Load Balancer | string | External Load Balancer resource ID. |
| externalLoadBalancerProbesId | External Load Balancer | array | External Load Balancer Probe resource IDs. |
| externalLoadBalancerRulesId | External Load Balancer | array | External Load Balancing Rules resource IDs. |
| inboundMgmtNatPool | Management Public IP Address | string | Management NAT Pool resource ID. |
| inboundSshNatPool | Management Public IP Address | string | SSH NAT Pool resource ID. |
| internalBackEndLoadBalancerId | Internal Load Balancer | string | Internal Back End Address Pool resource ID. |
| internalFrontEndLoadBalancerIp | Internal Load Balancer | string | Internal Front End resource ID. |
| internalLoadBalancer | Internal Load Balancer | string | Internal Load Balancer resource ID. |
| internalLoadBalancerProbesId | Internal Load Balancer | array | Internal Load Balancer Probe resource IDs. |
| mgmtIpIds | Management Public IP Address | array | Management Public IP Address resource IDs. |
| mgmtIps | Management Public IP Address | array | Management Public IP Addresses. |
| nsg0Id | Network Security Group | string | Network Security Group resource ID. |
| nsg1Id | Network Security Group | string | Network Security Group resource ID. |
| nsg2Id | Network Security Group | string | Network Security Group resource ID. |
| nsgIds | Network Security Group | array | Network Security Group resource ID. |


## Resource Creation Flow Chart

![Resource Creation Flow Chart](https://github.com/F5Networks/f5-azure-arm-templates-v2/blob/v2.3.0.0/examples/images/azure-dag-module.png)
