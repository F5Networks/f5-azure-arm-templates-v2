# Deploying Function Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)


## Contents

- [Deploying Function Template](#deploying-function-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)
    - [Contributor License Agreement](#contributor-license-agreement)

## Introduction

This template creates the Azure function app, hosting plan, key vault, application insights, and storage account resources required for revoking licenses from a BIG-IQ system based on current Azure Virtual Machine Scale Set capacity. By default, the function app executes every 2 minutes; however, you can adjust this interval from the function app timer trigger configuration after deployment is complete.


## Prerequisites

- You must provide the Azure resource ID of a Virtual Machine Scale Set with BIG-IP instances licensed via BIG-IQ.
- You must provide the Azure resource ID of the Virtual Network where the BIG-IQ system used to license the BIG-IP instances is deployed.
- The licensing API of the BIG-IQ system used to license the BIG-IP instances must be accessible from the Azure function app.
- You must provide either the license pool name or utility licensing information used to license the BIG-IP instances.
- The function app name created by this template must be globally unique. Do not reuse the same functionAppName parameter value in multiple deployments.
- This template must be deployed in the same resource group as the Virtual Machine Scale Set resource.
- This template creates an Azure system-assigned Managed Identity and assigns the role of Contributor to it on the scope of the resource group where the template is deployed. You must have sufficient permissions to create the identity and role assignment.

## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add function.json as a linked template into your templated solution.
 
 - BIG-IQ license class must use unreachable: Because the Azure function for license revocation filters license assignments based on the assignment tenant value, you must specify "reachable: false" in your F5 Declarative Onboarding license class declaration. See the F5 Declarative Onboarding [documentation](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/big-iq-licensing.html#license-class) for more information.

 - How to find outbound IP addresses for Azure function: If you specified a public IP address for the bigIqAddress parameter, you may need to configure the Azure network security group(s) for BIG-IQ management access to allow requests from the IP addresses allocated to the Azure function. In the Azure portal, you can find the list of function source IP addresses by clicking on the function app name, then clicking **Settings > Properties > Additional Outbound IP Addresses**. This list includes all possible source IP addresses used by the Azure function. 

- Disable SSL warnings in Azure function: By default, the Azure function is created with the F5_DISABLE_SSL_WARNINGS environment variable set to "False". When revoking licenses from a BIG-IQ License Manager device that is configured to use a self-signed certificate, you can set F5_DISABLE_SSL_WARNINGS to "True" to suppress insecure connection warning messages (this is not recommended for production deployments). You can configure this setting in the Azure portal by clicking on the function app name, then clicking **Settings > Configuration > App Settings** and changing the value for F5_DISABLE_SSL_WARNINGS to "True".


### Template Input Parameters

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details.

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| bigIpRuntimeInitConfig | No |  | string | Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format, or an escaped JSON string to use for f5-bigip-runtime-init configuration. |
| functionAppName | No | "functionApp" | string | Supply a name for the new function app. |
| functionAppSku | No | {"Tier": "ElasticPremium","Name": "EP1"}, | object | Supply a configuration for the function app server farm plan SKU (premium or appservice) in JSON format. Information about server farm plans is available [here](https://learn.microsoft.com/en-us/azure/templates/microsoft.web/serverfarms?pivots=deployment-language-arm-template). |
| functionAppVnetId | No |  | string | The fully-qualified resource ID of the Azure Virtual Network where BIG-IQ is deployed. This is required when connecting to BIG-IQ via a private IP address; the Azure function app will be granted ingress permission to the virtual network. When specifying an Azure public IP address for bigIqAddress, leave the default of **Default**. |
| secretId | No |  | string | The full URL of the secretId, including KeyVault Name. For example: https://yourvaultname.vault.azure.net/secrets/yoursecretid. |
| userAssignManagedIdentity | No |  | string | Enter user-assigned management identity ID to be associated to Virtual Machine Scale Set. Leave default if not used. |
| tagValues| No | {"application": "f5demoapp", "cost": "f5cost", "environment": "f5env", "group": "f5group", "owner": "f5owner"}, | object | List of tags to add to created resources. |
| vmssId | No |  | string | Supply the fully-qualified resource ID of the Azure Virtual Machine Scale Set to be monitored. |

### Template Outputs

| Name | Required Resource | Type | Description |
| --- | --- | --- | --- |
| applicationInsightsId | Application Insights | string | Application Insights resource ID. |
| functionAppId | Function App | string | Function App resource ID. |
| hostingPlanId | Server Farm | string | Hosting Plan resource ID. |
| keyVaultId | KeyVault | string | KeyVault resource ID. |
| roleAssignmentId | Role Assignment | string | Role Assignment resource ID. |
| storageAccountId | Storage Account | string | Storage Account resource ID. |

## Resource Creation Flow Chart

![Resource Creation Flow Chart](https://github.com/F5Networks/f5-azure-arm-templates-v2/blob/v2.8.0.0/examples/images/azure-function-module.png)


### Contributor License Agreement

Individuals or business entities who contribute to this project must have
completed and submitted the F5 Contributor License Agreement.
 system-assigned Managed Identity and assigns the role of Contributor to it on the scope of the resource group where the template is deployed. You must have sufficient permissions to create the identity and role assignment.
- Your BIG-IP instance license assignments must contain the tenant attribute. The value of this attribute is used to limit revocation to instances from a specific Azure Virtual Machine Scale Set deployment. If no value is specified for bigIqTenant when deploying this template, the tenant value defaults to the name of the Azure Virtual Machine Scale Set.
