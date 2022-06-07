# Deploying Access Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)

## Contents

- [Deploying Access Template](#deploying-access-template)
    - [Contents](#contents)
    - [Introduction](#introduction)
    - [Prerequisites](#prerequisites)
    - [Important Configuration Notes](#important-configuration-notes)
    - [Resources Provisioning](#resources-provisioning)
        - [RBAC Permissions by Solution Type](#rbac-permissions-by-solution-type)
        - [Template Input Parameters](#template-input-parameters)
        - [Template Outputs](#template-outputs)
    - [Resource Creation Flow Chart](#resource-creation-flow-chart)

## Introduction

This solution uses an ARM template to launch a stack for provisioning Access related items. This template can be deployed as a standalone; however, the main intention is to use as a module for provisioning Access related resources:

  - Custom Role Definition
  - Managed Identity
  - Key Vault Access Policy

This solution creates RBAC permissions based on the following **solutionTypes**:

  - standard
    - Service Discovery *(used by AS3)*
    - Azure Insights and Log Analytics *(used by Telemetry Streaming)*
  - logging
    - Azure Insights and Log Analytics *(used by Telemetry Streaming)*
  - failover
    - Permissions from standard + 
    - Update permissions for IP addresses/routes *(used by Cloud Failover Extension)*

Additionally, when providing the identifier of an existing Azure Key Vault secret for the secretId input parameter, the Azure user-assigned managed identity created by this template is granted **get** and **list** access to the provided secret. These permissions are also customizable. **NOTE: The secretId is required by F5 BIG-IP Runtime Init when deploying the failover or standard solutions (if licensing via BIG-IQ).**


## Prerequisites

  - None. This template does not require provisioning of additional resources.

## Important Configuration Notes

  - This template provisions resources based on conditions. See [Resources Provisioning](#resources-provisioning) for more details on each resource's minimal requirements.
  - A sample template, 'sample_linked.json', is included in the project. Use this example to see how to add a template as a linked template into your templated solution.
 
## Resources Provisioning

  * [Role Definition](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-definitions)
    - Creates custom role definition by default.
    - Requires providing `roleName` and `roleDescription` parameters for successful provisioning.
    - If `customRolePermissions` is provided, the supplied value will overwrite the default solution permissions.
  * [Managed Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
    - Requires providing `userAssignedIdentityName` parameter.
    - Used as dependency for provisioning KeyVault and Secrets.
    - If `userAssignedIdentityName` is not provided, the template creates a standalone role definition that can be added to a System-Assigned Managed Identity.
  * [KeyVault Access Policy](https://docs.microsoft.com/en-us/azure/key-vault/general/basic-concepts)
    - Dependent on Azure Managed Identity.
    - Adds the required permissions to the KeyVault Access Policy ACLs.
    - Requires providing the full `secretId`, including KeyVault ID.

### RBAC Permissions by Solution Type

These are the RBAC permissions produced by each type of solution supported by this template. For more details about the purpose of each permission, see the [CFE documentation for Azure Cloud](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/azure.html#rbac-role-definition)

| Permission | Solution Type |
| --- | --- |
| */read | logging | 
| Microsoft.Authorization/*/read | standard, failover, logging |
| Microsoft.Compute/locations/*/read | standard, failover, logging |
| Microsoft.Compute/virtualMachines/*/read | standard | 
| Microsoft.Compute/virtualMachines/extensions/* | logging | 
| Microsoft.Compute/virtualMachineScaleSets/*/read | standard | 
| Microsoft.Compute/virtualMachineScaleSets/networkInterfaces/read| standard | 
| Microsoft.HybridCompute/machines/extensions/write | logging | 
| Microsoft.Insights/alertRules/* | logging | 
| Microsoft.Insights/diagnosticSettings/* | logging | 
| Microsoft.Insights/Metrics/Write | logging | 
| Microsoft.Insights/Register/Action | logging | 
| Microsoft.Insights/Telemetry/Write | logging | 
| Microsoft.Network/*/join/action | failover | 
| Microsoft.Network/networkInterfaces/read | standard, failover | 
| Microsoft.Network/networkInterfaces/write | failover | 
| Microsoft.Network/publicIPAddresses/read | standard, failover | 
| Microsoft.Network/publicIPAddresses/write | failover | 
| Microsoft.Network/routeTables/*/read | failover | 
| Microsoft.Network/routeTables/*/write | failover | 
| Microsoft.OperationalInsights/* | logging | 
| Microsoft.OperationsManagement/* | logging | 
| Microsoft.Resources/deployments/* | logging | 
| Microsoft.Resources/subscriptions/read | logging | 
| Microsoft.Resources/subscriptions/resourceGroups/deployments/* | logging | 
| Microsoft.Resources/subscriptions/resourceGroups/read | standard, failover | 
| Microsoft.Storage/storageAccounts/listKeys/action | failover, logging | 
| Microsoft.Storage/storageAccounts/read | failover |
| Microsoft.Support/* | logging | 

### Template Input Parameters

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details.

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| customAssignableScopes | No |  | array | List of scopes applied to Role. If not specified, the deployment resource group is added to the list of assignable scopes. |
| customRolePermissions| No |  | array | Array of custom permissions for the roleDefinition. If specified, the solutionType selection has no effect and you must provide the complete set of required permissions. |
| keyVaultPermissionsKeys | No | "get",	"list" | array | Array of permissions allowed on KeyVault Secrets for role. If not specified, **get** and **list** permissions are assigned. |
| keyVaultPermissionsSecrets | No | "get",	"list" | array | Array of permissions allowed on KeyVault Secrets for role. If not specified, **get** and **list** permissions are assigned. |
| roleDescription | No | Role created by the Access template. | string | Description for role. |
| roleName| Yes |  | string | Provides value for role definition which will be created by the template. |
| secretId | No |  | string | The full URL of the secretId, including KeyVault Name. For example: https://yourvaultname.vault.azure.net/secrets/yoursecretid. |
| solutionType | No | standard | string | Specifies solution type. Allowed values are 'standard', 'failover', and 'logging'. |
| tagValues | No | "application": "APP", "cost": "COST", "environment": "ENV", "group": "GROUP", "owner": "OWNER" | object | Default key/value resource tags will be added to the resources in this deployment. If you would like the values to be unique, adjust them as needed for each key. |
| userAssignedIdentityName | No |  | string | User-Assigned Identity name. |

### Template Outputs

| Name | Required Resource | Type | Description |
| --- | --- | --- | --- |
| keyVaultName | Key Vault | string | Key Vault name |
| roleDefinitionId | Role Definition | string | Role definition resource ID |
| secretId | Secret | string | Secret ID |
| userAssignedIdentityId | User-Assigned Identity | string | User-assigned identity name |

## Resource Creation Flow Chart


![Resource Creation Flow Chart](https://github.com/F5Networks/f5-azure-arm-templates-v2/blob/v2.3.0.0/examples/images/azure-access-module.png)
