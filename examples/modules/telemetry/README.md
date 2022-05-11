
# Deploying Network Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)

## Contents

- [Deploying Telemetry Template](#deploying-telemetry-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)

## Introduction

This ARM template creates Telemetry module intended to setup infrastructure (i.e. Azure Log Workspace) to enable Remote Logging

## Prerequisites

 - None
 
## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add telemetry.json as a linked template into your templated solution.


### Template Input Parameters

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details.

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| uniqueString | Yes |  | string | Unique DNS Name for the Public IP address used to access the Virtual Machine and postfix resource names. |
| sku | No | PerGB2018 | string | Specifies the service tier of the workspace: Standalone, PerNode, and Per-GB. |
| tagValues | No | {"application": "APP", "cost": "COST", "environment": "ENV", "group": "GROUP", "owner": "OWNER"}, | object | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique adjust them as needed for each key. |
| workbookDisplayName | No | "F5 BIG-IP WAF View" | string | The friendly name for the workbook that is used in the Gallery or Saved List.  This name must be unique within a resource group. |
| workspaceName | No | "f5telemetry" | string | Specifies the name of the workspace. |

### Template Outputs

| Name | Required Resource | Type | Description |
| --- | --- | --- | --- |
| workspaceName | None | string | Workspace Name. |
| workspaceResourceId | None  | string | Workspace Resource ID. |
| workspaceId | None | string | Workspace ID. |
| workbookName | None | string | Workbook name. |
| workbookId | None | string | Workbook ID. |


