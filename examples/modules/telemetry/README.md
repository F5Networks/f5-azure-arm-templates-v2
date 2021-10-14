
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

| Parameter | Required | Description |
| --- | --- | --- |
| uniqueString | Yes | Unique DNS Name for the Public IP address used to access the Virtual Machine and postfix resource names. |
| sku | No | Specifies the service tier of the workspace: Standalone, PerNode, Per-GB |
| tagValues | No | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique adjust them as needed for each key. |
| workbookDisplayName | No | The friendly name for the workbook that is used in the Gallery or Saved List.  This name must be unique within a resource group. |
| workbookType | No | The gallery that the workbook will been shown under. Supported values include workbook, tsg, etc. Usually, this is 'workbook' | 
| workspaceName | No | Specifies the name of the workspace. |
### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| workspaceName | Workspace Name | None | string |
| workspaceResourceId | Workspace Resource ID | None  | string |
| workspaceId | Workspace ID | None | string |
| workbookName | Workbook name | None | string |
| workbookId | Workbook ID | None | string |


