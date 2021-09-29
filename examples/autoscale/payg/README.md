# Deploying the BIG-IP VE in Azure - Example Autoscale BIG-IP WAF (LTM + ASM) - VM Scale Set (Frontend via ALB) - PAYG Licensing

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)

## Contents

  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Diagram](#diagram)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Deploying this Solution](#deploying-this-solution)
    - [Deploying via the Azure Deploy Button](#deploying-via-the-azure-deploy-button)
    - [Deploying via the Azure CLI](#deploying-via-the-azure-cli)
    - [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment)
  - [Validation](#validation)
    - [Validating the Deployment](#validating-the-deployment)
    - [Testing the WAF Service](#testing-the-waf-service)
    - [Viewing the Azure Workbook in Azure Log Analytics Workspace](#viewing-the-azure-workbook-in-azure-log-analytics-workspace)
  - [Updating this Solution](#updating-this-solution)
    - [Updating the Configuration](#updating-the-configuration)
    - [Upgrading the BIG-IP VE Image](#upgrading-the-big-ip-ve-image)
  - [Deleting this Solution](#deleting-this-solution)
  - [Troubleshooting Steps](#troubleshooting-steps)
  - [Security](#security)
  - [BIG-IP versions](#big-ip-versions)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)
  - [Documentation](#documentation)
  - [Getting Help](#getting-help)
    - [Filing Issues](#filing-issues)


## Introduction

This solution uses a parent template to launch several linked child templates (modules) to create a full example stack for the BIG-IP Autoscale solution. The linked templates are located in the examples/modules directories in this repository. **F5 recommends you clone this repository and modify these templates to fit your use case.** 

The modules below create the following resources:

- **Network**: This template creates Azure Virtual Networks, Subnets, and Route Tables.
- **Application**: This template creates a generic example application for use when demonstrating live traffic through the BIG-IPs.
- **Disaggregation** *(DAG/Ingress)*: This template creates resources required to get traffic to the BIG-IP, including Azure Network Security Groups, Public IP Addresses, internal/external Load Balancers, and accompanying resources such as load balancing rules, NAT rules, and probes.
- **Access**: This template creates an Azure Managed User Identity, KeyVault, and secret used to set the admin password on the BIG-IP instances.
- **BIG-IP**: This template creates the Microsoft Azure VM Scale Set with F5 BIG-IP Virtual Editions provisioned with Local Traffic Manager (LTM) and Application Security Manager (ASM). Traffic flows from the Azure load balancer to the BIG-IP VE instances and then to the application servers. The BIG-IP VE(s) are configured in single-NIC mode. Auto scaling means that as certain thresholds are reached, the number of BIG-IP VE instances automatically increases or decreases accordingly. The BIG-IP module template can be deployed separately from the example template provided here into an "existing" stack.
- **Telemetry**: This template creates resources to support sending metrics and remote logging (for example, an Azure Log Analytics Workspace and Workbook). 

This solution leverages more traditional Autoscale configuration management practices where each instance is created with an identical configuration as defined in the Scale Set's "model". Scale Set sizes are no longer restricted to the small limitations of the cluster. The BIG-IP's configuration, now defined in a single convenient YAML or JSON [F5 BIG-IP Runtime Init](https://github.com/F5Networks/f5-bigip-runtime-init) configuration file, leverages [F5 Automation Tool Chain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) declarations which are easier to author, validate and maintain as code. For instance, if you need to change the configuration on the BIG-IPs in the deployment, instead of updating the existing instances directly, you update the instance model by passing a new config file (which references the updated Automation Toolchain declarations) via template's bigIpRuntimeInitConfig input parameter. The model will be responsible for maintaining the configuration across the deployment, updating existing instances and deploying new instances with the latest configuration.


## Diagram

![Configuration Example](diagram.png)

## Prerequisites

  - This solution requires an Azure account that can provision objects described in the solution and [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups).
    - Azure Portal: [Create a Resource Group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups)
    - Azure CLI: 
      ```bash
      az group create -n ${RESOURCE_GROUP} -l ${REGION}
      ```
  - This solution requires an [SSH key](https://docs.microsoft.com/en-us/azure/virtual-machines/ssh-keys-portal) for access to the BIG-IP instances.
  - This solution requires you to accept any Azure Marketplace "License/Terms and Conditions" for the images used in this solution.
    - By default, this solution uses [F5 Advanced WAF with LTM, IPI and TC (PAYG - 25Mbps)](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/f5-networks.f5-big-ip-advanced-waf?tab=PlansAndPrice)
    - Azure CLI: 
      ```bash
      az vm image terms accept --urn f5-networks:f5-big-ip-advanced-waf:f5-big-awf-plus-hourly-25mbps:16.0.101000
      ```
    - For more marketplace terms information, see Azure [documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage#deploy-an-image-with-marketplace-terms). 
    - See Azure's [documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/data-platform-logs) for more information and [Changing the BIG-IP Deployment](#remote-logging) for customization details. 


## Important Configuration Notes

- By default, this solution does not create a custom BIG-IP WebUI user as instances are not intended to be managed directly. However, an sshKey is installed to provide CLI access for demonstration and debugging purposes. 
  - **Disclaimer:** ***Accessing or logging into the instances themselves is for demonstration and debugging purposes only. All configuration changes should be applied by updating the model via the template instead.***
  - See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more details.

- This solution requires Internet access for: 
  1. Downloading additional F5 software components used for onboarding and configuring the BIG-IP (via github.com). *NOTE: access via web proxy is not currently supported. Other options include 1) hosting the file locally and modifying the runtime-init package url and configuration files to point to local URLs instead or 2) baking them into a custom image (BYOL images only), using the [F5 Image Generation Tool](https://clouddocs.f5.com/cloud/public/v1/ve-image-gen_index.html).*
  2. Contacting native cloud services for various cloud integrations: 
    - *Onboarding*:
        - [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) - to fetch secrets from native vault services
    - *Operation*:
        - [F5 Application Services 3](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/) - for features like Service Discovery
        - [F5 Telemetry Streaming](https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/) - for logging and reporting
    - Additional cloud services like [Private endpoints](https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#connecting-to-private-endpoints) can be used to address calls to native services traversing the Internet.
  - See [Security](#security) section for more details. 

- F5 ARM templates do not reconfigure existing Azure resources, such as network security groups. Depending on your configuration, you may need to configure these resources to allow the BIG-IP VE(s) to receive traffic for your application. Similarly, the DAG example template that deploys Azure Load Balancer(s) configures load balancing rules and probes on those resources to forward external traffic to the BIG-IP(s) on standard ports 443 and 80. F5 recommends cloning this repository and modifying the module templates to fit your use case.

- If you have cloned this repository to modify the templates or BIG-IP config files and published to your own location, you can use the **templateBaseUrl** and **artifactLocation** input parameters to specify the new location of the customized templates and the **bigIpRuntimeInitConfig** input parameter to specify the new location of the BIG-IP Runtime-Init config. See main [/examples/README.md](../../README.md#cloud-configuration) for more template customization details. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more BIG-IP customization details.

- In this solution, the BIG-IP VE has the [LTM](https://f5.com/products/big-ip/local-traffic-manager-ltm) and [ASM](https://f5.com/products/big-ip/application-security-manager-asm) modules enabled to provide advanced traffic management and web application security functionality. 

- If you are deploying the solution into an Azure region that supports Availability Zones, you can specify True for the useAvailabilityZones parameter. See [Azure Availability Zones](https://docs.microsoft.com/en-us/azure/availability-zones/az-region#azure-regions-with-availability-zones) for a list of regions that support Availability Zones.

- This template can send non-identifiable statistical information to F5 Networks to help us improve our templates. You can disable this functionality by setting the **autoPhonehome** system class property value to false in the F5 Declarative Onboarding declaration. See [Sending statistical information to F5](#sending-statistical-information-to-f5).

- See [trouble shooting steps](#troubleshooting-steps) for more details.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| appContainerName | No | The name of a container to download and install which is used for the example application server. If this value is left blank, the application module template is not deployed. |
| appScalingMaxSize | No | Maximum number of application instances (2-100) that can be created in the Autoscale Group. |
| appScalingMinSize | No | Minimum number of application instances (1-99) you want available in the Autoscale Group. |
| artifactLocation | No | The directory, relative to the templateBaseUrl, where the modules folder is located. |
| bigIpImage | No | Two formats accepted. `URN` of the image to use in Azure marketplace or `ID` of custom image. Example URN value: `f5-networks:f5-big-ip-advanced-waf:f5-big-awf-plus-hourly-25mbps:16.0.101000`. You can find the URNs of F5 marketplace images in the README for this template or by running the command: `az vm image list --output yaml --publisher f5-networks --all`. See https://clouddocs.f5.com/cloud/public/v1/azure/Azure_download.html for information on creating custom BIG-IP image. |
| bigIpInstanceType | No | Enter a valid instance type. |
| bigIpMaxBatchInstancePercent | No | The maximum percentage of total virtual machine instances that will be upgraded simultaneously by the rolling upgrade in one batch. |
| bigIpMaxUnhealthyInstancePercent | No | The maximum percentage of the total virtual machine instances in the scale set that can be simultaneously unhealthy. |
| bigIpMaxUnhealthyUpgradedInstancePercent | No | The maximum percentage of upgraded virtual machine instances that can be found to be in an unhealthy state. |
| bigIpPauseTimeBetweenBatches | No | The wait time between completing the update for all virtual machines in one batch and starting the next batch. |
| bigIpRuntimeInitConfig | No | Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format, or an escaped JSON string to use for f5-bigip-runtime-init configuration. |
| bigIpRuntimeInitPackageUrl | No | Supply a URL to the bigip-runtime-init package. |
| bigIpScalingMaxSize | No | Maximum number of BIG-IP instances (2-100) that can be created in the Autoscale Group. |
| bigIpScalingMinSize | No | Minimum number of BIG-IP instances (1-99) you want available in the Autoscale Group. |
| bigIpScaleInCpuThreshold | No | The percentage of CPU utilization that should trigger a scale in event. |
| bigIpScaleInThroughputThreshold | No | The amount of throughput (**bytes**) that should trigger a scale in event. Note: The default value is equal to 10 MB. |
| bigIpScaleInTimeWindow | No | The time window required to trigger a scale in event. This is used to determine the amount of time needed for a threshold to be breached, as well as to prevent excessive scaling events (flapping). **Note:** Allowed values are 1-60 (minutes). |
| bigIpScaleOutCpuThreshold | No | The percentage of CPU utilization that should trigger a scale out event. |
| bigIpScaleOutThroughputThreshold | No | The amount of throughput (**bytes**) that should trigger a scale out event. Note: The default value is equal to 20 MB. |
| bigIpScaleOutTimeWindow | No | The time window required to trigger a scale out event. This is used to determine the amount of time needed for a threshold to be breached, as well as to prevent excessive scaling events (flapping). **Note:** Allowed values are 1-60 (minutes). |
| createWorkspace | No | This deployment will create a workspace and workbook as part of the Telemetry module, intended for enabling Remote Logging using Azure Log Workspace. |
| provisionPublicIp | No | Select true if you would like to provision a public IP address for accessing the BIG-IP instance(s). |
| restrictedSrcAddressMgmt | Yes | An IP address range (CIDR) used to restrict SSH and management GUI access to the BIG-IP Management or Bastion Host instances. NOTE: The vpc cidr is automatically added for internal usage, ex. access via bastion host, clustering, etc. **IMPORTANT**: Please restrict to your client, for example 'X.X.X.X/32'. WARNING - For eval purposes only. Production should never have the BIG-IP Management interface exposed to Internet.|
| restrictedSrcAddressApp | Yes | An IP address range (CIDR) that can be used to restrict access web traffic (80/443) to the EC2 instances, for example 'X.X.X.X/32' for a host, '0.0.0.0/0' for the Internet, etc. NOTE: The vpc cidr is automatically added for internal usage. |
| sshKey | Yes | Supply the public key that will be used for SSH authentication to the BIG-IP and application virtual machines. Note: This should be the public key as a string, typically starting with **---- BEGIN SSH2 PUBLIC KEY ----** and ending with **---- END SSH2 PUBLIC KEY ----**. |
| tagValues | No | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique adjust them as needed for each key. |
| templateBaseUrl | No | The publicly accessible URL where the linked ARM templates are located. |
| uniqueString | Yes | A prefix that will be used to name template resources. Because some resources require globally unique names, we recommend using a unique value. |
| useAvailabilityZones | No | This deployment can deploy resources into Azure Availability Zones (if the region supports it). If that is not desired the input should be set false. If the region does not support availability zones the input should be set to false. |
| workspaceId | No | Azure Logging Workspace ID. For example: "0ad61913-8c82-4d58-b93c-89d612812c84" |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| appUsername | Application user name | Application Template | string |
| appVmssName | Application Virtual Machine Scale Set name | Application Template | string |
| appVmssId | Application Virtual Machine Scale Set resource ID | Application Template | string |
| bigIpUsername | BIG-IP user name | BIG-IP Template | string |
| virtualNetworkId | Virtual Network resource ID | Network Template | string |
| bastionVmssName | Bastion Virtual Machine Scale Set name | Bastion Template | String |
| bastionVmssId | Bastion Virtual Machine Scale Set resource ID | Bastion Template | String |
| bigIpVmssId | BIG-IP Virtual Machine Scale Set resource ID | BIG-IP Template | string |
| bigIpVmssName | BIG-IP Virtual Machine Scale Set name| BIG-IP Template | string |
| wafPublicIps | WAF Service Public IP Addresses | DAG Template | array |


## Deploying this Solution

See [Prerequisites](#prerequisites).

Two options for deploying this solution include:

- Using the [Azure deploy button](#deploying-via-the-azure-deploy-button) - in the Azure Portal
- Using [CLI Tools](#deploying-via-the-azure-cli)


### Deploying via the Azure Deploy Button

An easy way to deploy this Azure Arm templates is to use the deploy button below:<br>

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FF5Networks%2Ff5-azure-arm-templates-v2%2Fv1.4.0.0%2Fexamples%2Fautoscale%2Fpayg%2Fazuredeploy.json)

*Step 1: Custom Template Page* 
  - Select or Create New Resource Group.
  - Fill in the *REQUIRED* parameters (with * next to them). 
    - **sshKey**
    - **restrictedSrcAddressApp**
    - **restrictedSrcAddressMgmt**
    - **uniqueString**
  - Click "Next: Review + Create".

*Step 2: Custom Template Page*
  - After "Validation Passed" click "Create".

For next steps, see [Validating the Deployment](#validating-the-deployment).

### Deploying via the Azure CLI

As an alternative to deploying through the Azure Portal (GUI), each solution provides an example Azure CLI 2.0 command to deploy the ARM template. 

#### Azure CLI (2.0) Script Example

*NOTE: First replace parameter values with `<YOUR_VALUE>` with your values. Assumes Prerequisites have been created, Resource Group and optionally Log Analytics Workspace have been created.*

```bash
#/bin/bash
RESOURCE_GROUP="myGroupName"
REGION="eastus"
DEPLOYMENT_NAME="parentTemplate"
TEMPLATE_URI="https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v1.4.0.0/examples/autoscale/payg/azuredeploy.json"
DEPLOY_PARAMS='{"templateBaseUrl":{"value":"https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/"},"artifactLocation":{"value":"v1.4.0.0/examples/"},"uniqueString":{"value":"<YOUR_VALUE>"},"sshKey":{"value":"<YOUR_VALUE>"},"bigIpInstanceType":{"value":"Standard_DS4_v2"},"bigIpImage":{"value":"f5-networks:f5-big-ip-advanced-waf:f5-big-awf-plus-hourly-25mbps:16.0.101000"},"appContainerName":{"value":"f5devcentral/f5-demo-app:latest"},"restrictedSrcAddressApp":{"value":"<YOUR_VALUE>"},"restrictedSrcAddressMgmt":{"value":"<YOUR_VALUE>"},"bigIpRuntimeInitConfig":{"value":"https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v1.4.0.0/examples/autoscale/bigip-configurations/runtime-init-conf-payg.yaml"},"useAvailabilityZones":{"value":false},"workspaceId":{"value":"<YOUR_VALUE>"},"tagValues":{"value":{"application":"APP","cost":"COST","environment":"ENV","group":"GROUP","owner":"OWNER"}}}'
DEPLOY_PARAMS_FILE=deploy_params.json
echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}

az group create -n ${RESOURCE_GROUP} -l ${REGION}
az deployment group create --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} --template-uri ${TEMPLATE_URI}  --parameters @${DEPLOY_PARAMS_FILE}
```

For next steps, see [Validating the Deployment](#validating-the-deployment).


### Changing the BIG-IP Deployment

You will most likely want or need to change the BIG-IP configuration. This generally involves referencing or customizing a [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) configuration file and passing it through the **bigIpRuntimeInitConfig** template parameter as a URL or inline json. 

Example from azuredeploy.parameters.json
```json
    "useAvailabilityZones": {
        "value": false
    },
    "bigIpRuntimeInitConfig": {
        "value": "https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v1.4.0.0/examples/autoscale/bigip-configurations/runtime-init-conf-payg.yaml"
    },

```

**IMPORTANT**: Note the "raw.githubusercontent.com". Any URLs pointing to github **must** use the raw file format. 

The F5 BIG-IP Runtime Init configuration file can also be formatted in json and/or passed directly inline:

Example:
```json
        "useAvailabilityZones": {
            "value": false
        },
        "bigIpRuntimeInitConfig": {
            "value": "{\"pre_onboard_enabled\":[],\"runtime_parameters\":[{\"name\":\"HOST_NAME\",\"type\":\"metadata\",\"metadataProvider\":{\"type\":\"compute\",\"environment\":\"azure\",\"field\":\"name\"}},{\"name\":\"RESOURCE_GROUP_NAME\",\"type\":\"url\",\"value\":\"http://169.254.169.254/metadata/instance/compute?api-version=2020-09-01\",\"query\":\"resourceGroupName\",\"headers\":[{\"name\":\"Metadata\",\"value\":true}]},{\"name\":\"UNIQUE_STRING\",\"type\":\"url\",\"value\":\"http://169.254.169.254/metadata/instance/compute/tagsList?api-version=2020-09-01\",\"query\":\"[?name==\'uniqueString\'].value|[0]\",\"headers\":[{\"name\":\"Metadata\",\"value\":true}]},{\"name\":\"WORKSPACE_ID\",\"type\":\"url\",\"value\":\"http://169.254.169.254/metadata/instance/compute/tagsList?api-version=2020-09-01\",\"query\":\"[?name==\'workspaceId\'].value|[0]\",\"headers\":[{\"name\":\"Metadata\",\"value\":true}]},{\"name\":\"SUBSCRIPTION_ID\",\"type\":\"url\",\"value\":\"http://169.254.169.254/metadata/instance/compute?api-version=2020-09-01\",\"query\":\"subscriptionId\",\"headers\":[{\"name\":\"Metadata\",\"value\":true}]},{\"name\":\"REGION\",\"type\":\"url\",\"value\":\"http://169.254.169.254/metadata/instance/compute?api-version=2020-09-01\",\"query\":\"location\",\"headers\":[{\"name\":\"Metadata\",\"value\":true}]}],\"bigip_ready_enabled\":[],\"extension_packages\":{\"install_operations\":[{\"extensionType\":\"do\",\"extensionVersion\":\"1.19.0\",\"extensionHash\":\"15c1b919954a91b9ad1e469f49b7a0915b20de494b7a032da9eb258bbb7b6c49\"},{\"extensionType\":\"as3\",\"extensionVersion\":\"3.26.0\",\"extensionHash\":\"b33a96c84b77cff60249b7a53b6de29cc1e932d7d94de80cc77fb69e0b9a45a0\"},{\"extensionType\":\"ts\",\"extensionVersion\":\"1.18.0\",\"extensionHash\":\"de4c82cafe503e65b751fcacfb2f169912ad5ce1645e13c5135dca972299174a\"}]},\"extension_services\":{\"service_operations\":[{\"extensionType\":\"do\",\"type\":\"inline\",\"value\":{\"schemaVersion\":\"1.0.0\",\"class\":\"Device\",\"label\":\"Autoscale 1NIC BIG-IP declaration for Declarative Onboarding with PAYG license\",\"async\":true,\"Common\":{\"class\":\"Tenant\",\"My_DbVariables\":{\"class\":\"DbVariables\",\"provision.extramb\":1000,\"restjavad.useextramb\":true,\"ui.advisory.color\":\"blue\",\"ui.advisory.text\":\"Provisioned via Runtime Init and DO\"},\"My_Dns\":{\"class\":\"DNS\",\"nameServers\":[\"168.63.129.16\"]},\"My_Ntp\":{\"class\":\"NTP\",\"servers\":[\"0.pool.ntp.org\"],\"timezone\":\"UTC\"},\"My_Provisioning\":{\"asm\":\"nominal\",\"class\":\"Provision\",\"ltm\":\"nominal\"},\"My_System\":{\"class\":\"System\",\"autoPhonehome\":true,\"hostname\":\"{{{HOST_NAME}}}.local\"}}}},{\"extensionType\":\"as3\",\"type\":\"inline\",\"value\":{\"schemaVersion\":\"3.0.0\",\"class\":\"ADC\",\"remark\":\"Autoscale\",\"label\":\"Autoscale\",\"Tenant_1\":{\"class\":\"Tenant\",\"Shared\":{\"class\":\"Application\",\"template\":\"shared\",\"telemetry_local_rule\":{\"remark\":\"Only required when TS is a local listener\",\"class\":\"iRule\",\"iRule\":\"when CLIENT_ACCEPTED {\\n  node 127.0.0.1 6514\\n}\"},\"telemetry_local\":{\"remark\":\"Only required when TS is a local listener\",\"class\":\"Service_TCP\",\"virtualAddresses\":[\"255.255.255.254\"],\"virtualPort\":6514,\"iRules\":[\"telemetry_local_rule\"]},\"telemetry\":{\"class\":\"Pool\",\"members\":[{\"enable\":true,\"serverAddresses\":[\"255.255.255.254\"],\"servicePort\":6514}],\"monitors\":[{\"bigip\":\"/Common/tcp\"}]},\"telemetry_hsl\":{\"class\":\"Log_Destination\",\"type\":\"remote-high-speed-log\",\"protocol\":\"tcp\",\"pool\":{\"use\":\"telemetry\"}},\"telemetry_formatted\":{\"class\":\"Log_Destination\",\"type\":\"splunk\",\"forwardTo\":{\"use\":\"telemetry_hsl\"}},\"telemetry_publisher\":{\"class\":\"Log_Publisher\",\"destinations\":[{\"use\":\"telemetry_formatted\"}]},\"telemetry_asm_security_log_profile\":{\"class\":\"Security_Log_Profile\",\"application\":{\"localStorage\":false,\"remoteStorage\":\"splunk\",\"servers\":[{\"address\":\"255.255.255.254\",\"port\":\"6514\"}],\"storageFilter\":{\"requestType\":\"all\"}}},\"shared_pool\":{\"class\":\"Pool\",\"remark\":\"Service 1 shared pool\",\"members\":[{\"addressDiscovery\":\"azure\",\"addressRealm\":\"private\",\"resourceGroup\":\"{{{RESOURCE_GROUP_NAME}}}\",\"resourceId\":\"{{{UNIQUE_STRING}}}-app-vmss\",\"resourceType\":\"scaleSet\",\"servicePort\":80,\"subscriptionId\":\"{{{SUBSCRIPTION_ID}}}\",\"updateInterval\":60,\"useManagedIdentity\":true}],\"monitors\":[\"http\"]}},\"HTTP_Service\":{\"class\":\"Application\",\"template\":\"http\",\"serviceMain\":{\"class\":\"Service_HTTP\",\"virtualAddresses\":[\"0.0.0.0\"],\"policyWAF\":{\"use\":\"WAFPolicy\"},\"pool\":\"/Tenant_1/Shared/shared_pool\",\"securityLogProfiles\":[{\"use\":\"/Tenant_1/Shared/telemetry_asm_security_log_profile\"}]},\"WAFPolicy\":{\"class\":\"WAF_Policy\",\"url\":\"https://raw.githubusercontent.com/F5Networks/f5-azure-arm-templates-v2/v1.4.0.0/examples/autoscale/bigip-configurations/Rapid_Depolyment_Policy_13_1.xml\",\"enforcementMode\":\"blocking\",\"ignoreChanges\":false}},\"HTTPS_Service\":{\"class\":\"Application\",\"template\":\"https\",\"serviceMain\":{\"class\":\"Service_HTTPS\",\"virtualAddresses\":[\"0.0.0.0\"],\"policyWAF\":{\"use\":\"WAFPolicy\"},\"pool\":\"/Tenant_1/Shared/shared_pool\",\"securityLogProfiles\":[{\"use\":\"/Tenant_1/Shared/telemetry_asm_security_log_profile\"}],\"serverTLS\":{\"bigip\":\"/Common/clientssl\"},\"redirect80\":false},\"WAFPolicy\":{\"class\":\"WAF_Policy\",\"url\":\"https://raw.githubusercontent.com/F5Networks/f5-azure-arm-templates-v2/v1.4.0.0/examples/autoscale/bigip-configurations/Rapid_Depolyment_Policy_13_1.xml\",\"enforcementMode\":\"blocking\",\"ignoreChanges\":false}}}}},{\"extensionType\":\"ts\",\"type\":\"inline\",\"value\":{\"class\":\"Telemetry\",\"controls\":{\"class\":\"Controls\",\"logLevel\":\"info\"},\"My_Metrics_Namespace\":{\"class\":\"Telemetry_Namespace\",\"My_System_Poller\":{\"class\":\"Telemetry_System_Poller\",\"interval\":60,\"actions\":[{\"includeData\":{},\"locations\":{\"system\":{\"cpu\":true}}}]},\"My_Scaling_Endpoints\":{\"class\":\"Telemetry_Endpoints\",\"items\":{\"throughputIn\":{\"name\":\"throughputIn\",\"path\":\"/mgmt/tm/sys/performance/throughput?$top=1\&$select=Current\"},\"hostname\":{\"name\":\"hostname\",\"path\":\"/mgmt/tm/sys/global-settings?$select=hostname\"}}},\"My_Custom_Endpoints_Poller\":{\"class\":\"Telemetry_System_Poller\",\"interval\":60,\"endpointList\":[\"My_Scaling_Endpoints/hostname\",\"My_Scaling_Endpoints/throughputIn\"]},\"My_Telemetry_System\":{\"class\":\"Telemetry_System\",\"systemPoller\":[\"My_System_Poller\",\"My_Custom_Endpoints_Poller\"]},\"My_Azure_Application_Insights\":{\"appInsightsResourceName\":\"{{{UNIQUE_STRING}}}-insights\",\"class\":\"Telemetry_Consumer\",\"maxBatchIntervalMs\":5000,\"maxBatchSize\":250,\"type\":\"Azure_Application_Insights\",\"useManagedIdentity\":true}},\"My_Remote_Logs_Namespace\":{\"class\":\"Telemetry_Namespace\",\"My_Listener\":{\"class\":\"Telemetry_Listener\",\"port\":6514},\"My_Azure_Log_Analytics\":{\"class\":\"Telemetry_Consumer\",\"type\":\"Azure_Log_Analytics\",\"workspaceId\":\"{{{WORKSPACE_ID}}}\",\"useManagedIdentity\":true,\"region\":\"{{{REGION}}}\"}}}}]},\"post_onboard_enabled\":[]}"
    },
```

NOTE: If providing the json inline as a template parameter, you must escape all double quotes so it can be passed as a single parameter string.

*TIP: If you don't have an easy way to host your own config files, passing the config as inline json via the template input parameter might be the quickest / most accessible option to test out different BIG-IP configs using this repository.*
 
F5 has provided the following example configuration files in the `examples/autoscale/bigip-configurations` folder:

- `runtime-init-conf-bigiq.yaml` - This configuration file installs packages and creates WAF-protected services for a BIG-IQ licensed deployment based on the Automation Toolchain declaration URLs listed above.
- `runtime-init-conf-payg.yaml` - This inline configuration file installs packages and creates WAF-protected services for a PAYG licensed deployment.
- `Rapid_Deployment_Policy_13_1.xml` - This ASM security policy is supported for BIG-IP 13.1 and later.

See [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) for more examples. 
 
By default, this solution deploys the `runtime-init-conf-payg.yaml` configuration. 

This example configuration does not require any modifications to deploy successfully *(Disclaimer: "Successfully" implies the template deploys without errors and deploys BIG-IP WAFs capable of passing traffic. To be fully functional as designed, you need to have satisfied the [Prerequisites](#prerequisites).* However, in production, these files are commonly customized further. Some examples of small customizations or modifications are provided below. 
 

The example AS3 declaration in this configuration uses [Service Discovery](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/service-discovery.html#using-service-discovery-with-as3) to populate the pool with the private IP addresses of application servers in a Virtual Machine Scale Set. By default, the fields for the service discovery configuration (**resourceGroup**, **subscriptionId** and ***uniqueString***) are rendered similarly from Azure metadata. If the application VMSS are located in a different resource group or subscription, you can modify these values. 

To change the Pool configuration:

  1. Edit/modify the AS3 Declaration (AS3) declaration in a corresponding runtime-init config file with the new `Pool` values. 

Example:
```yaml
              class: Pool
              remark: Service 1 shared pool
              members:
                _ addressDiscovery: azure
                  addressRealm: private
                  resourceGroup: <YOUR_RESOURCE_GROUP>
                  resourceId: <YOUR_VMSS_NAME>
                  resourceType: scaleSet
                  servicePort: 80
                  subscriptionId: <YOUR_SUBSCRIPTION_ID>
                  updateInterval: 60
                  useManagedIdentity: true
```

  - *NOTE:* 
    - The managed identity assigned to the BIG-IP VE instance(s) must have read permissions on the VMSS resource.
    - The Service Discovery configuration listed above targets a specific application VMSS ID to reduce the number of requests made to the Azure API endpoints. When choosing capacity for the BIG-IP VE and application VMSS, it is possible to exceed the API request limits. Consult the Azure resource manager [documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/request-limits-and-throttling) for more information.

  - Or even with another pool configuration entirely. For example, using the [FQDN](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/declarations/discovery.html#using-an-fqdn-pool-to-identify-pool-members) Service Discovery instead to point to a DNS name.

```yaml
              class: Pool
              remark: Service 1 shared pool
              members:
              - addressDiscovery: fqdn
                autoPopulate: true
                hostname: <WWW.YOURSITE.COM>
                servicePort: 80
```

  2. Publish/host the customized runtime-init config file at a location reachable by the BIG-IP at deploy time (for example, GitHub, Azure Storage, etc.) or render/format to send as inline JSON.
  3. Update the **bigIpRuntimeInitConfig** input parameter to reference the new URL or inline JSON of the updated configuration.
  4. Deploy or redeploy.

The example configuration contains a Telemetry Streaming declaration that sends metrics to Azure Insights and logs to Azure Log Analytics. By default, the fields for the Telemetry Streaming declaration (**appInsightsResourceName** and **workspaceId**) are rendered from values from Azure metadata and/or a specific naming convention. These values can be modified to use different static values. 

To change the logging destination: 

  1. *OPTIONAL*: If the remote logging destination requires authentication, edit/modify the the corresponding runtime-init config file to fetch the secret from Azure Vault.

Example:
```yaml
runtime_parameters:
  - name: LOGGING_API_KEY
    type: secret
    secretProvider:
      type: KeyVault
      environment: azure
      vaultUrl: 'https://<YOUR_VAULT_NAME>.vault.azure.net'
      secretId: <YOUR_SECRET_NAME>
```
  NOTE: Ensure the Azure Managed User Identity assigned to BIG-IP has permissions to access this secret.

  2. Edit/modify the Telemetry Streaming (TS) declaration in a corresponding runtime-init config file with the new logging consumer/destination. 

Example:
```yaml
        My_Remote_Logs_Namespace:
          class: Telemetry_Namespace
          My_Listener:
            class: Telemetry_Listener
            port: 6514
          My_Azure_Log_Analytics:
            class: Telemetry_Consumer
            type: Azure_Log_Analytics
            workspaceId: '{{{WORKSPACE_ID}}}'
            useManagedIdentity: true
            region: '{{{REGION}}}'

```
to:

```yaml
        My_Remote_Logs_Namespace:
          class: Telemetry_Namespace
          My_Listener:
            class: Telemetry_Listener
            port: 6514            
          My_Remote_Consumer:
            class: Telemetry_Consumer
            type: Splunk
            host: <YOUR_HOST>
            protocol: https
            port: 8088
            passphrase:
                cipherText: '{{{ LOGGING_API_KEY }}}'
            compressionType: gzip
```

  2. Publish/host the customized runtime-init config file at a location reachable by the BIG-IP at deploy time (for example, GitHub, Azure Storage, etc.) or render/format to send as inline JSON.
  3. Update the **bigIpRuntimeInitConfig** input parameter to reference the new URL or inline JSON of the updated configuration.
  4. Deploy or redeploy.


## Validation

This section describes how to validate the template deployment, test the WAF service, and troubleshoot common problems.


### Validating the Deployment

To view the status of the example and module template deployments, navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments**. You should see a series of deployments, including one each for the example templates as well as the accessTemplate, appTemplate, networkTemplate, dagTemplate, and bigIpTemplate. The deployment status for each template deployment should be "Succeeded".

Expected Deploy time for entire stack =~ 13-15 minutes.

If any of the deployments are in a failed state, proceed to the [Troubleshooting Steps](#troubleshooting-steps) section below.

### Testing the WAF Service

To test the WAF service, perform the following steps:
- Check the VM Scale Set instance health state; instance health is based on Azure's ability to connect to your application via the VM Scale Set's load balancer
  - Navigate to **Resource Groups > *RESOURCE_GROUP* > Overview > *uniqueId*-vmss" > Instances**.
  - The health state for each instance should be "Healthy". If the state is "Unhealthy", proceed to the [Troubleshooting Steps](#troubleshooting-steps) section.
- Obtain the IP address of the WAF service:
  - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments > *DEPLOYMENT_NAME* > Outputs > wafPublicIps**.
  - **Azure CLI**: 
      ```bash
      az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME}  -o tsv --query properties.outputs.wafPublicIps.value[0]
      ```
- Verify the application is responding:
  - Paste the IP address in a browser: ```https://${IP_ADDRESS_FROM_OUTPUT}```
      - NOTE: By default, the Virtual Service starts with a self-signed cert. Follow your browsers instructions for accepting self-signed certs (for example, if using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click "Advanced" button, Click "Accept Risk and Continue", etc.).
  - Use curl: 
      ```shell
       curl -sko /dev/null -w '%{response_code}\n' https://${IP_ADDRESS_FROM_OUTPUT}
       ```
- Verify the WAF is configured to block illegal requests:
    ```shell
    curl -sk -X DELETE https://${IP_ADDRESS_FROM_OUTPUT}
    ```
  - The response should include a message that the request was blocked, and a reference support ID
    Example:
    ```shell
    $ curl -sko /dev/null -w '%{response_code}\n' https://55.55.55.55
    200
    $ curl -sk -X DELETE https://55.55.55.55
    <html><head><title>Request Rejected</title></head><body>The requested URL was rejected. Please consult with your administrator.<br><br>Your support ID is: 2394594827598561347<br><br><a href='javascript:history.back();'>[Go Back]</a></body></html>
    ```

### Viewing the Azure Workbook in Azure Log Analytics Workspace 

 - If left at the defaults, an Azure Log Analytics Workspace named "f5telemetry" with Azure Workbook named "F5 BIG-IP WAF View" is created. 

    - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Overview > f5telemetry(Workspace) > "F5 BIG-IP WAF VIEW"(Workbook)**.  
    - Review any violations
      

### Accessing the BIG-IP


- Obtain the IP address of the BIG-IP Management Port:

  - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Overview > *uniqueId*-bigip-vmss > Instances > *instance name* > Essentials > Public address**.
  - **Azure CLI**: 
      ```shell
      az vmss list-instance-public-ips --name ${uniqueId}-bigip-vmss -g ${RESOURCE_GROUP} -o tsv --query [].ipAddress
      ```

  - Or if you are going through a bastion host (when **provisionPublicIP** = **false**):
       - Obtain the Public IP address of a bastion host: 
         - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Overview > *uniqueId*-bastion-vmss > Instances > *instance name* > Essentials > Public address**.
         - **Azure CLI**: 
             ```shell
             az vmss list-instance-public-ips --name ${uniqueId}-bastion-vmss -g ${RESOURCE_GROUP} -o tsv --query [].ipAddress
             ```

       - Obtain the Private IP address of a BIG-IP host: 
          - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Overview > *uniqueId*-bigip-vmss > Instances > *instance name* > Essentials > Private address**
          - **Azure CLI**: 
              ```shell 
              az vmss nic list --vmss-name ${uniqueId}-bigip-vmss -g ${RESOURCE_GROUP} -o tsv --query [].ipConfigurations[].privateIpAddress
              ```

#### SSH

  - **SSH key authentication**: 
      ```bash
      ssh admin@${IP_ADDRESS_FROM_OUTPUT} -i ${YOUR_PRIVATE_SSH_KEY}

- OR if you are going through a bastion host (when **provisionPublicIP** = **false**):

    From your desktop client/shell, create an SSH tunnel:
    ```bash
    ssh -i [your-private-ssh-key.pem] -o ProxyCommand='ssh -i [your-private-ssh-key.pem] -W %h:%p [AZURE-USER]@[BASTION-HOST-PUBLIC-IP]' [BIG-IP-USER]@[BIG-IP-MGMT-PRIVATE-IP]
    ```

    Replace the variables in brackets before submitting the command.

    For example:
    ```bash
    ssh -i ~/.ssh/mykey.pem -o ProxyCommand='ssh -i ~/.ssh/mykey.pem -W %h:%p azureuser@34.82.102.190' admin@10.0.0.11
    ```
        
#### WebUI 

- Login in via WebUI:
  - As mentioned above, no password is configured by default. If you would like or need to login to the GUI for debugging or inspection, you can create a custom username/password by logging in to admin account via SSH (per above) and use tmsh to create one:
    At the TMSH prompt ```admin@(bigip1)(cfg-sync Standalone)(Active)(/Common)(tmos)#```:
      ```shell
      create auth user <YOUR_WEBUI_USERNAME> password <YOUR_STRONG_PASSWORD> partition-access add { all-partitions { role admin } }

      save sys config
      ```

  - Open a browser to the Management IP
    - ```https://${IP_ADDRESS_FROM_OUTPUT}:8443```

        

    - OR when you are going through a bastion host (when **provisionPublicIP** = **false**):

        From your desktop client/shell, create an SSH tunnel:
        ```bash
        ssh -i [keyname-passed-to-template.pem] [AZURE-USER]@[BASTION-HOST-PUBLIC-IP] -L 8443:[BIG-IP-MGMT-PRIVATE-IP]:[BIGIP-GUI-PORT]
        ```
        For example:
        ```bash
        ssh -i ~/.ssh/mykey.pem azureuser@34.82.102.190 -L 8443:10.0.0.11:8443
        ```

        You should now be able to open a browser to the BIG-IP UI from your desktop:

        https://localhost:8443
      

  - NOTE: 
    - By default, for Single NIC deployments, the management port is 8443.
    - By default, the BIG-IP's WebUI starts with a self-signed cert. Follow your browsers instructions for accepting self-signed certs (for example, if using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click "Advanced" button, Click "Accept Risk and Continue" ).

- To Login: 
  - username: `<YOUR_WEBUI_USERNAME>`
  - password: `<YOUR_STRONG_PASSWORD>`

### Further Exploring

#### WebUI
 - Navigate to **Virtual Services > Partition**. Select Partition = `Tenant_1`
 - Navigate to **Local Traffic > Virtual Servers**. You should see two Virtual Services (one for HTTP and one for HTTPS). They should show up as Green. Click on them to look at the configuration *(declared in the AS3 declaration)*.

#### SSH

  - From tmsh shell, type 'bash' to enter the bash shell.
    - Examine BIG-IP configuration via [F5 Automation Toolchain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) declarations:
    ```bash
    curl -u admin: http://localhost:8100/mgmt/shared/declarative-onboarding | jq .
    curl -u admin: http://localhost:8100/mgmt/shared/appsvcs/declare | jq .
    curl -u admin: http://localhost:8100/mgmt/shared/telemetry/declare | jq . 
    ```
  - Examine the Runtime-Init Config downloaded: 
    ```bash 
    cat /config/cloud/runtime-init.conf
    ```


## Updating this Solution

### BIG-IP Lifecycle Management

As mentioned in the [Introduction](#introduction), if you need to change the configuration on the BIG-IPs in the deployment, instead of updating the existing instances directly, you update the instance model by passing a new config file (which references the updated Automation Toolchain declarations) via template's bigIpRuntimeInitConfig input parameter. The model will be responsible for maintaining the configuration across the deployment, updating existing instances and deploying new instances with the latest configuration.

This happens by leveraging Azure's VMSS [Rolling Upgrades](https://docs.microsoft.com/en-us/cli/azure/vmss/rolling-upgrade?view=azure-cli-latest) feature.

By default, Rolling Upgrades are configured to upgrade in batches of 20% with zero pause time in between sets and minimum of 20% of healthy nodes available. To modify, you can customize the `/module/bigip-autoscale` template.

#### Updating the Configuration

1. Modify the **bigIpRuntimeInitConfig** parameter value to trigger a model update. If using inline json, make a configuration change in parameter payload. If using a URL, reference a new URL. Example:
  - If using tags for versions, change from `v1.2.0.0`
    ```json
        "bigIpRuntimeInitConfig": {
          "value": "https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v1.2.0.0/examples/autoscale/bigip-configurations/runtime-init-conf-payg.yaml"
        },
    ```
    to `v1.4.0.0`
    ```json
        "bigIpRuntimeInitConfig": {
          "value": "https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v1.4.0.0/examples/autoscale/bigip-configurations/runtime-init-conf-payg.yaml"
        },
    ```
2. Re-deploy the template with new **bigIpRuntimeInitConfig** parameter
    ```bash
    az deployment group create --name ${DEPLOYMENT_NAME} --resource-group ${RESOURCE_GROUP} --template-uri https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v1.4.0.0/examples/autoscale/payg/azuredeploy.json  --parameters ${YOUR_NEW_PARAMETERS}
    ```  

#### Upgrading the BIG-IP VE Image
As new BIG-IP versions are released, existing VM scale sets can be upgraded to use those new images with same procedure. 

1. Modify the **bigIpImage** input parameter value to new BIG-IP version. 

2. Re-deploy the template with new **bigIpImage** parameter
    ```bash 
    az deployment group create --name ${DEPLOYMENT_NAME} --resource-group ${RESOURCE_GROUP} --template-uri https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v1.4.0.0/examples/autoscale/payg/azuredeploy.json  --parameters @azuredeploy.parameters.json
    ```

**Note:** Due to a known issue, you cannot upgrade an existing VM Scale Set from BIG-IP version 15.1.200000 to version 16.0.101000. To upgrade between these versions, you must first delete the VM Scale Set resource before re-deploying the template.

#### Lifecycle Troubleshooting

If a new configuration update fails (for example, invalid config, typo, etc.) and Rolling Upgrade fails to complete.

1. [Cancel](https://docs.microsoft.com/en-us/cli/azure/deployment/group?view=azure-cli-latest#az_deployment_group_cancel) any hung Deployments
    - **Console**: 
      - Navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments**.
          - Click "Cancel".
    - **Azure CLI**: 
        ```bash 
        az deployment group cancel -n ${DEPLOYMENT_NAME} --resource-group ${RESOURCE_GROUP}
        ```
2. [Cancel](https://docs.microsoft.com/en-us/cli/azure/vmss/rolling-upgrade?view=azure-cli-latest#az_vmss_rolling_upgrade_cancel) the Rolling Update
    - **Console**: 
      - Navigate to **Resource Groups > *RESOURCE_GROUP* > *${uniqueId}-bigip-vmss***. Click the "View details" link at the end of the banner at the top of the screen "A Rolling Upgrade is in progress. To update the virtual machine scale set, you must wait until the upgrade is done or cancel the upgrade operation. View details."
          - Click "Cancel".
    - **Azure CLI**: 
      ```bash 
      az vmss rolling-upgrade get-latest -n ${uniqueId}-bigip-vmss  --resource-group ${RESOURCE_GROUP}
      az vmss rolling-upgrade cancel -n ${uniqueId}-bigip-vmss  --resource-group ${RESOURCE_GROUP}
      ```
3. Modify parameters to update the model.
    - Modify the parameter that resulted in failure (for example, a previous or working **bigIpRuntimeInitConfig** value or image).
    - Modify Scaling Size to deploy new instances .
      - Increase **bigIpScalingMinSize** parameter value by 1 or more.
4. Re-deploy the template with new parameter values ( the failed parameter and **bigIpScalingMinSize**).
5. Confirm newly instantiated instance(s) are "Healthy".
6. [Delete](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-cli#remove-vms-from-a-scale-set) failed instances.
    - Navigate to the VM Scale Set instances pane.
    - Select either all failed instances or one at a time. Select `Delete`.

#### Configure Scale Event Notifications

**Note:** You can specify email addresses for notifications within the solution and they will be applied automatically. You can also manually configure them via the VM Scale Set configuration options available within the Azure Portal.

You can add notifications when scale up/down events happen, either in the form of email or webhooks. The following shows an example of adding an email address via the Azure Resources Explorer that receives an email from Azure whenever a scale up/down event occurs.

Log in to the [Azure Resource Explorer](https://resources.azure.com) and then navigate to the Autoscale settings (**Subscriptions > Resource Groups >** *resource group where deployed* **> Providers > Microsoft.Insights > Autoscalesettings > autoscaleconfig**). At the top of the screen click **Read/Write**, and then from the Autoscale settings, click **Edit**. Replace the current **notifications** json key with the example below, making sure to update the email address(es). Select PUT and notifications will be sent to the email addresses listed.

```json
    "notifications": [
      {
        "operation": "Scale",
        "email": {
          "sendToSubscriptionAdministrator": false,
          "sendToSubscriptionCoAdministrators": false,
          "customEmails": [
            "email@f5.com"
          ]
        },
        "webhooks": null
      }
    ]
```


## Deleting this Solution

### Deleting the deployment via Azure Portal 

1. Navigate to **Home** and select the Resource Groups Icon.

2. Select your Resource Group by clicking on the link.

3. Click "Delete Resource Group".

4. Type the Name of the Resource Group when prompted to confirm.

5. Click "Delete".

### Deleting the deployment using the Azure CLI

```bash
az group delete -n ${RESOURCE_GROUP}
```


### Troubleshooting Steps

There are generally two classes of issues:

1. Template deployment itself failed
2. Resource(s) within the template failed to deploy

To verify that all templates deployed successfully, follow the instructions under **Validating the Deployment** above to locate the failed deployment(s).

Click on the name of a failed deployment and then click Events. Click the link in the red banner at the top of the deployment overview for details about the failure cause. 

Additionally, if the template passed validation but individual template resources have failed to deploy, you can see more information by expanding Deployment Details, then clicking on the Operation details column for the failed resource. **When creating a GitHub issue for a template, please include as much information as possible from the failed Azure deployment/resource events.**

Common deployment failure causes include:
- Required fields were left empty or contained incorrect values (input type mismatch, prohibited characters, malformed JSON, etc.) causing template validation failure
- Insufficient permissions to create the deployment or resources created by a deployment
- Resource limitations (exceeded limit of IP addresses or compute resources, etc.)
- Azure service issues (these will usually surface as 503 internal server errors in the deployment status error message)

If all deployments completed "successfully" but maybe the BIG-IP or Service is not reachable, then log in to the BIG-IP instance via SSH to confirm BIG-IP deployment was successful (for example, if startup scripts completed as expected on the BIG-IP). To verify BIG-IP deployment, perform the following steps:
- Obtain the IP address of the BIG-IP instance. See instructions [above](#accessing-the-bigip-ip)
- Check startup-script to make sure was installed/interpolated correctly:
  - ```cat /var/lib/waagent/customData  | base64 -d```
- Check the logs (in order of invocation):
  - cloud-agent logs:
    - */var/log/waagent.log*
    - */var/log/boot.log*
    - */var/log/cloud-init.log*
    - */var/log/cloud-init-output.log*
  - runtime-init Logs:
    - */var/log/cloud/startup-script.log*: This file contains events that happen prior to execution of f5-bigip-runtime-init. If the files required by the deployment fail to download, for example, you will see those events logged here.
    - */var/log/cloud/bigipRuntimeInit.log*: This file contains events logged by the f5-bigip-runtime-init onboarding utility. If the configuration is invalid causing onboarding to fail, you will see those events logged here. If deployment is successful, you will see an event with the body "All operations completed successfully".
  - Automation Tool Chain Logs:
    - */var/log/restnoded/restnoded.log*: This file contains events logged by the F5 Automation Toolchain components. If an Automation Toolchain declaration fails to deploy, you will see more details for those events logged here.
- *GENERAL LOG TIP*: Search most critical error level errors first (for example, egrep -i err /var/log/<Logname>).

If you are unable to login to the BIG-IP instance(s), you can navigate to **Resource Groups > *RESOURCE_GROUP* > Overview > *uniqueId*-vmss > Instances > *INSTANCE_NAME* > Support and Troubleshooting > Serial console** for additional information from Azure.


## Security

This ARM template downloads helper code to configure the BIG-IP system:

- f5-bigip-runtime-init.gz.run: The self-extracting installer for the F5 BIG-IP Runtime Init RPM can be verified against a SHA256 checksum provided as a release asset on the F5 BIG-IP Runtime Init public GitHub repository, for example: https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.2.1/f5-bigip-runtime-init-1.2.1-1.gz.run.sha256.
- F5 BIG-IP Runtime Init: The self-extracting installer script extracts, verifies, and installs the F5 BIG-IP Runtime Init RPM package. Package files are signed by F5 and automatically verified using GPG.
- F5 Automation Toolchain components: F5 BIG-IP Runtime Init downloads, installs, and configures the F5 Automation Toolchain components. Although it is optional, F5 recommends adding the extensionHash field to each extension install operation in the configuration file. The presence of this field triggers verification of the downloaded component package checksum against the provided value. The checksum values are published as release assets on each extension's public GitHub repository, for example: https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.18.0/f5-appsvcs-3.18.0-4.noarch.rpm.sha256

The following configuration file will verify the Declarative Onboarding and Application Services extensions before configuring AS3 from a local file:

```yaml
runtime_parameters: []
extension_packages:
    install_operations:
        - extensionType: do
          extensionVersion: 1.19.0
          extensionHash: 15c1b919954a91b9ad1e469f49b7a0915b20de494b7a032da9eb258bbb7b6c49
        - extensionType: as3
          extensionVersion: 3.26.0
          extensionHash: b33a96c84b77cff60249b7a53b6de29cc1e932d7d94de80cc77fb69e0b9a45a0
extension_services:
    service_operations:
      - extensionType: as3
        type: url
        value: file:///examples/declarations/as3.json
```

More information about F5 BIG-IP Runtime Init and additional examples can be found in the [GitHub repository](https://github.com/F5Networks/f5-bigip-runtime-init/blob/main/README.md).

If you want to verify the integrity of the template itself, F5 provides checksums for all of our templates. For instructions and the checksums to compare against, see [checksums-for-f5-supported-cft-and-arm-templates-on-github](https://devcentral.f5.com/codeshare/checksums-for-f5-supported-cft-and-arm-templates-on-github-1014).

List of endpoints BIG-IP may contact during onboarding:
- BIG-IP image default:
    - vector2.brightcloud.com (by BIG-IP image for [IPI subscription validation](https://support.f5.com/csp/article/K03011490) )
- Solution / Onboarding:
    - github.com (for downloading helper packages mentioned above)
    - f5-cft.s3.amazonaws.com (downloading GPG Key and other helper configuration files)
    - license.f5.com (licensing functions)
- Telemetry:
    - www-google-analytics.l.google.com
    - product-s.apis.f5.com.
    - f5-prod-webdev-prod.apigee.net.
    - global.azure-devices-provisioning.net.
    - id-prod-global-endpoint.trafficmanager.net.


## BIG-IP Versions

These templates have been tested and validated with the following versions of BIG-IP. 

| Azure BIG-IP Image Version | BIG-IP Version |
| --- | --- |
| 16.1.000000 | 16.1.0 Build 0.0.0 |
| 14.1.404001 | 14.1.4.4 Build 0.0.1 |


## Supported Instance Types and Hypervisors

- For a list of supported Azure instance types for this solution, see the [Azure instances for BIG-IP VE](http://clouddocs.f5.com/cloud/public/v1/azure/Azure_singleNIC.html#azure-instances-for-big-ip-ve).

- For a list of versions of the BIG-IP Virtual Edition (VE) and F5 licenses that are supported on specific hypervisors and Microsoft Azure, see [supported-hypervisor-matrix](https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ve-supported-hypervisor-matrix.html).


## Documentation

For more information on F5 solutions for Azure, including manual configuration procedures for some deployment scenarios, see the Azure section of [Public Cloud Docs](http://clouddocs.f5.com/cloud/public/v1/).


## Getting Help

Due to the heavy customization requirements of external cloud resources and BIG-IP configurations in these solutions, F5 does not provide technical support for deploying, customizing, or troubleshooting the templates themselves. However, the various underlying products and components used (for example: [F5 BIG-IP Virtual Edition](https://clouddocs.f5.com/cloud/public/v1/), [F5 BIG-IP Runtime Init](https://github.com/F5Networks/f5-bigip-runtime-init), [F5 Automation Toolchain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) extensions, and [Cloud Failover Extension (CFE)](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/)) in the solutions located here are F5-supported and capable of being deployed with other orchestration tools. Read more about [Support Policies](https://www.f5.com/company/policies/support-policies). Problems found with the templates deployed as-is should be reported via a GitHub issue.

For help with authoring and support for custom CST2 templates, we recommend engaging F5 Professional Services (PS).

### Filing Issues

Use the **Issues** link on the GitHub menu bar in this repository for items such as enhancement or feature requests and bugs found when deploying the example templates as-is. Tell us as much as you can about what you found and how you found it.