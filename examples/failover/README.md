# Deploying the BIG-IP VE in Azure - Example Failover BIG-IP HA Cluster - Virtual Machines

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)

## Contents

- [Deploying the BIG-IP VE in Azure - Example Failover BIG-IP HA Cluster - Virtual Machines](#deploying-the-big-ip-ve-in-azure---example-failover-big-ip-ha-cluster---virtual-machines)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Diagram](#diagram)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
    - [Existing Network Template Input Parameters](#existing-network-template-input-parameters)
    - [Existing Network Template Outputs](#existing-network-template-outputs)
  - [Deploying this Solution](#deploying-this-solution)
    - [Deploying via the Azure Deploy button](#deploying-via-the-azure-deploy-button)
    - [Deploying via the Azure CLI](#deploying-via-the-azure-cli)
      - [Azure CLI (2.0) Script Example](#azure-cli-20-script-example)
    - [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment)
  - [Validation](#validation)
    - [Validating the Deployment](#validating-the-deployment)
    - [Accessing the BIG-IP](#accessing-the-big-ip)
      - [SSH](#ssh)
      - [WebUI](#webui)
    - [Further Exploring](#further-exploring)
      - [WebUI](#webui-1)
      - [SSH](#ssh-1)
    - [Testing the WAF Service](#testing-the-waf-service)
    - [Testing Failover](#testing-failover)
  - [Deleting this Solution](#deleting-this-solution)
    - [Deleting the deployment via Azure Portal](#deleting-the-deployment-via-azure-portal)
    - [Deleting the deployment using the Azure CLI](#deleting-the-deployment-using-the-azure-cli)
  - [Troubleshooting Steps](#troubleshooting-steps)
  - [Security](#security)
  - [BIG-IP Versions](#big-ip-versions)
  - [Supported Instance Types and Hypervisors](#supported-instance-types-and-hypervisors)
  - [Documentation](#documentation)
  - [Getting Help](#getting-help)
    - [Filing Issues](#filing-issues)


## Introduction

The goal of this solution is to reduce prerequisites and complexity to a minimum so with a few clicks, a user can quickly deploy a BIG-IP, login and begin exploring the BIG-IP platform in a working full-stack deployment capable of passing traffic. 

This solution uses a parent template to launch several linked child templates (modules) to create an example BIG-IP Highly Available (HA) solution using the F5 Cloud Failover Extension (CFE).  For information about this deployment, see the F5 Cloud Failover Extension [documentation](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/azure.html). The linked templates are located in the [`examples/modules`](https://github.com/F5Networks/f5-azure-arm-templates-v2/tree/main/examples/modules) directory in this repository. *F5 recommends cloning this repository and modifying these templates to fit your use case.*

***Full Stack (azuredeploy.json)***<br>
Use the *azuredeploy.json* parent template to deploy an example full stack HA solution, complete with virtual network, bastion *(optional)*, dag/ingress, access, BIG-IP(s) and example web application.  

***Existing Network Stack (azuredeploy-existing-network.json)***<br>
Use the *azuredeploy-existing-network.json* parent template to deploy HA solution into an existing network infrastructure. This template expects the virtual network, subnets, and bastion host(s) have already been deployed. A example web application is also not part of this parent template as it intended use is for an existing environment.

The modules below create the following cloud resources:

- **Network**: This template creates Azure Virtual Networks, Subnets, and Route Tables. *(Full stack only)*
- **Bastion**: This template creates a bastion host for accessing the BIG-IP instances when no public IP address is used for the management interfaces. *(Full stack only)*
- **Application**: This template creates a generic example application for use when demonstrating live traffic through the BIG-IP instance. *(Full stack only)* 
- **Disaggregation** *(DAG/Ingress)*: This template creates resources required to get traffic to the BIG-IP, including Network Security Groups, Public IP Addresses, NAT rules and probes.
- **Access**: This template creates a User-Assigned Managed Identity, grants it access to the supplied BIG-IP password Key Vault secret, and assigns it to the BIG-IP instances.
- **BIG-IP**: This template creates F5 BIG-IP Virtual Edition instances provisioned with Local Traffic Manager (LTM) and (optionally) Application Security Manager (ASM). 


By default, this solution creates a VNet with four subnets, an example Web Application instance two PAYG BIG-IP instances with three network interfaces (one for management and two for dataplane/application traffic - called external and internal). Application traffic from the Internet traverses an external network interface configured with both public and private IP addresses. Traffic to the application traverses an internal network interface configured with a private IP address.

***DISCLAIMER/WARNING***: To reduce prerequisites and complexity to a bare minimum for evaluation purposes only, this solution optionally allows immediate access to the management interface via a Public IP. At the very *minimum*, configure the **restrictedSrcAddressMgmt** parameter to limit access to your client IP or trusted network. In production deployments, management access should never be directly exposed to the Internet and instead should be accessed via typical management best practices like jumpboxes/bastion hosts, VPNs, etc.


## Diagram

![Configuration Example](diagram.png)

For information about this type of deployment, see the F5 Cloud Failover Extension [documentation](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/azure.html).

## Prerequisites

  - This solution requires an Azure account that can provision objects described in the solution and [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups).
    - Azure Portal: [Create a Resource Group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups)
    - Azure CLI: 
      ```bash
      az group create -n ${RESOURCE_GROUP} -l ${REGION}
      ```
  - A location to host your custom BIG-IP config (runtime-init.conf) with your own Key Vault information. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for customization details.
  - This solution requires an Azure Key Vault and secret containing the password to access and cluster the HA Pair, provided in the format https://yourvaultname.vault.azure.net/secrets/yoursecretid or https://yourvaultname.vault.azure.net/secrets/yoursecretid/yoursecretversion. 

    For example, to create the secret using the Azure CLI:
      ```bash
      az keyvault create --name [YOUR_VAULT_NAME] --resource-group [YOUR_RESOURCE_GROUP] --location [YOUR_REGION]
      az keyvault secret set --vault-name [YOUR_VAULT_NAME] --name [YOUR_SECRET_ID] --value "[YOUR_BIGIP_PASSWORD]"
      ```
      - *NOTE:*
        - Vault names in Azure are DNS based and hence globally unique.
        - The Vault can be in a different resource group than the BIG-IP resource group.
        - The user or service principal deploying the template must have `Key Vault Contributor` role in order for the Access template to create an Access Policy for the secret. For more information, see Azure [Docs](https://docs.microsoft.com/en-us/azure/key-vault/general/rbac-guide?tabs=azure-cli#azure-built-in-roles-for-key-vault-data-plane-operations)
  - This solution requires an [SSH key](https://docs.microsoft.com/en-us/azure/virtual-machines/ssh-keys-portal) for access to the BIG-IP instances. For more information about creating a key pair for use in Azure, see Azure SSH key [documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys).
- This solution requires you to accept any Azure Marketplace "License/Terms and Conditions" for the images used in this solution.
  - By default, this solution uses [F5 BIG-IP Virtual Edition - BEST (PAYG 25Mbps)](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/f5-networks.f5-big-ip-best?tab=PlansAndPrice)
  - Azure CLI: 
      ```bash
      az vm image terms accept --publisher f5-networks --offer f5-big-ip-best --plan f5-big-best-plus-hourly-25mbps
      ```
  - For more marketplace terms information, see Azure [documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage#deploy-an-image-with-marketplace-terms).


## Important Configuration Notes

- By default, this solution modifies the username **admin** with a password set to value of the Azure Key Vault secret which is provided in the input **bigIpPasswordSecretId** of the parent template.

- This solution requires Internet access for: 
  1. Downloading additional F5 software components used for onboarding and configuring the BIG-IP (via github.com). Internet access is required via the management interface and then via a dataplane interface (for example, external Self-IP) once a default route is configured. See [Overview of Mgmt Routing](https://support.f5.com/csp/article/K13284) for more details. By default, as a convenience, this solution provisions Public IPs to enable this but in a production environment, outbound access should be provided by a `routed` SNAT service (for example: NAT Gateway, custom firewall, etc.). *NOTE: access via web proxy is not currently supported. Other options include 1) hosting the file locally and modifying the runtime-init package URL and configuration files to point to local URLs instead or 2) baking them into a custom image, using the [F5 Image Generation Tool](https://clouddocs.f5.com/cloud/public/v1/ve-image-gen_index.html).*
  2. Contacting native cloud services for various cloud integrations: 
    - *Onboarding*:
        - [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) - to fetch secrets from native vault services
    - *Operation*:
        - [F5 Application Services 3](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/) - for features like Service Discovery
        - [Cloud Failover Extension (CFE)](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/) - for updating ip and routes mappings
    - Additional cloud services like [Private endpoints](https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#connecting-to-private-endpoints) can be used to address calls to native services traversing the Internet.
  - See [Security](#security) section for more details. 

- This solution template provides an **initial** deployment only for an "infrastructure" use case (meaning that it does not support managing the entire deployment exclusively via the template's "Redeploy" function). This solution leverages wa-agent to send the instance **customData**, which is only used to provide an initial BIG-IP configuration and not as the primary configuration API for a long-running platform. Although "Redeploy" can be used to update some cloud resources, as the BIG-IP configuration needs to align with the cloud resources, like IPs to NICs, updating one without the other can result in inconsistent states, while updating other resources, like the **image** or **instanceType**, can trigger an entire instance re-deloyment. For instance, to upgrade software versions, traditional in-place upgrades should be leveraged. See [AskF5 Knowledge Base](https://support.f5.com/csp/article/K84554955) and [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more information.

- If you have cloned this repository to modify the templates or BIG-IP config files and published to your own location, you can use the **templateBaseUrl** and **artifactLocation** input parameters to specify the new location of the customized templates and the **bigIpRuntimeInitConfig01** and **bigIpRuntimeInitConfig02** input parameters to specify the new location of the BIG-IP Runtime-Init configs. See main [/examples/README.md](../README.md#cloud-configuration) for more template customization details. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more BIG-IP customization details.

- In this solution, the BIG-IP VE has the [LTM](https://f5.com/products/big-ip/local-traffic-manager-ltm) and [ASM](https://f5.com/products/big-ip/application-security-manager-asm) (when **provisionExampleApp** is set to **true**) modules enabled to provide advanced traffic management and web application security functionality. 

- If you are deploying the solution into an Azure region that supports Availability Zones, you can specify True for the useAvailabilityZones parameter. See [Azure Availability Zones](https://docs.microsoft.com/en-us/azure/availability-zones/az-region#azure-regions-with-availability-zones) for a list of regions that support Availability Zones.

- This template can send non-identifiable statistical information to F5 Networks to help us improve our templates. You can disable this functionality by setting the **autoPhonehome** system class property value to false in the F5 Declarative Onboarding declaration. See [Sending statistical information to F5](#sending-statistical-information-to-f5).

- See [trouble shooting steps](#troubleshooting-steps) for more details.

### Template Input Parameters

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details.

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| appContainerName | No | "f5devcentral/f5-demo-app:latest" | string | The name of a container to download and install which is used for the example application server(s). If this value is left blank, the application module template is not deployed. |
| artifactLocation | No | "f5-azure-arm-templates-v2/v2.0.0.0/examples/" | string | The directory, relative to the templateBaseUrl, where the modules folder is located. |
| bigIpImage | No | "f5-networks:f5-big-ip-best:f5-big-best-plus-hourly-25mbps:16.1.202000" | string | Two formats accepted. `URN` of the image to use in Azure marketplace or `ID` of custom image. Example URN value: `f5-networks:f5-big-ip-best:f5-big-best-plus-hourly-25mbps:16.1.202000`. You can find the URNs of F5 marketplace images in the README for this template or by running the command: `az vm image list --output yaml --publisher f5-networks --all`. See https://clouddocs.f5.com/cloud/public/v1/azure/Azure_download.html for information on creating custom BIG-IP image. |
| bigIpInstanceType | No | "Standard_D8s_v4" | string | Enter a valid instance type. |
| bigIpPasswordSecretId | Yes | | string | The full URL of the secretId where the BIG-IP password is stored, including KeyVault Name. For example: https://yourvaultname.vault.azure.net/secrets/yoursecretid. This will be used by the BIG-IP to cluster with other devices. |
| bigIpRuntimeInitConfig01 | No | https://raw.githubusercontent.com/F5Networks/f5-azure-arm-templates-v2/v2.0.0.0/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance01-with-app.yaml | string | Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format, or an escaped JSON string to use for f5-bigip-runtime-init configuration. |
| bigIpRuntimeInitConfig02 | No | https://raw.githubusercontent.com/F5Networks/f5-azure-arm-templates-v2/v2.0.0.0/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance02-with-app.yaml | string | Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format, or an escaped JSON string to use for f5-bigip-runtime-init configuration. |
| bigIpRuntimeInitPackageUrl | No | https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.4.1/dist/f5-bigip-runtime-init-1.4.1-1.gz.run | string | Supply a URL to the bigip-runtime-init package. |
| cfeStorageAccountName | Yes |  | string | CFE storage account created and used for cloud-failover-extension. |
| cfeTag | No | "bigip_high_availability_solution" | string | Cloud Failover deployment tag value. |
| bigIpExternalSelfIp01 | No | "10.0.1.11" | string | External Private IP Address for BIGIP Instance 01. IP address parameter must be in the form x.x.x.x. |
| bigIpExternalSelfIp02 | No | "10.0.1.12" | string | External Private IP Address for BIGIP Instance 02. IP address parameter must be in the form x.x.x.x. |
| bigIpExternalVip01 | No | "10.0.1.101" | string | External private VIP Address for BIGIP Instance. IP address parameter must be in the form x.x.x.x. The address must reside in the same subnet and address space as the IP address provided for bigIpExternalSelfIp01. |
| bigIpInternalSelfIp01 | No | "10.0.2.11" | string | Internal Private IP Address for BIGIP Instance 01. IP address parameter must be in the form x.x.x.x. |
| bigIpInternalSelfIp02 | No | 10.0.2.12 | string | Internal Private IP Address for BIGIP Instance 02. IP address parameter must be in the form x.x.x.x. |
| bigIpMgmtAddress01 | No | 10.0.0.11 | string | Management Private IP Address for BIGIP Instance 01. IP address parameter must be in the form x.x.x.x. |
| bigIpMgmtAddress02 | No | 10.0.0.12 | string | Management Private IP Address for BIGIP Instance 02. IP address parameter must be in the form x.x.x.x. |
| bigIpPeerAddr | No | "10.0.1.11" | string | Type the static self IP address of the remote host here. Leave empty if not configuring peering with a remote host on this device. |
| provisionExampleApp | No | true | boolean | Flag to deploy the demo web application. |
| provisionPublicIpMgmt | No | true | boolean | Select true if you would like to provision a public IP address for accessing the BIG-IP instance(s). |
| restrictedSrcAddressApp | Yes |  | string | An IP address range (CIDR) that can be used to restrict access web traffic (80/443) to the BIG-IP instances, for example 'X.X.X.X/32' for a host, '0.0.0.0/0' for the Internet, etc. **NOTE**: The VPC CIDR is automatically added for internal use. |
| restrictedSrcAddressMgmt | Yes |  | string | An IP address or address range (in CIDR notation) used to restrict SSH and management GUI access to the BIG-IP Management or bastion host instances. **Important**: The VPC CIDR is automatically added for internal use (access via bastion host, clustering, etc.). Please do NOT use "0.0.0.0/0". Instead, restrict the IP address range to your client or trusted network, for example "55.55.55.55/32". Production should never expose the BIG-IP Management interface to the Internet. |
| sshKey | Yes | | string | Supply the public key that will be used for SSH authentication to the BIG-IP and application virtual machines. Note: This should be the public key as a string, typically starting with **ssh-rsa**. |
| tagValues | No | "application": "APP", "cost": "COST", "environment": "ENV", "group": "GROUP", "owner": "OWNER" | object | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique adjust them as needed for each key. |
| templateBaseUrl | No | https://cdn.f5.com/product/cloudsolutions/ | string | The publicly accessible URL where the linked ARM templates are located. |
| uniqueString | Yes |  | string | A prefix that will be used to name template resources. Because some resources require globally unique names, we recommend using a unique value. |
| useAvailabilityZones | No | false | boolean | This deployment can deploy resources into Azure Availability Zones (if the region supports it). If that is not desired the input should be set false. If the region does not support availability zones the input should be set to false. |

### Template Outputs

| Name | Required Resource | Type | Description |
| --- | --- | --- | --- |
| appPrivateIp | Application Template | string | Application Private IP Address |
| appUsername | Application Template | string | Application user name |
| appVmName | Application Template | string | Application Virtual Machine name |
| bastionPublicIp | Bastion Template | string | Bastion Public IP Address |
| bigIpInstance01ManagementPublicIp | BIG-IP Template | string | Management Private IP Address |
| bigIpInstance01ManagementPrivateIp | BIG-IP Template | string | Management Private IP Address |
| bigIpInstance01ManagementPublicUrl | Dag Template | string | Management Public IP Address |
| bigIpInstance01ManagementPrivateUrl | Dag Template | string | Management Public IP Address |
| bigIpInstance02ManagementPublicIp | BIG-IP Template | string | Management Private IP Address |
| bigIpInstance02ManagementPrivateIp | BIG-IP Template | string | Management Private IP Address |
| bigIpInstance02ManagementPublicUrl | Dag Template | string | Management Public IP Address |
| bigIpInstance02ManagementPrivateUrl | Dag Template | string | Management Public IP Address |
| bigIpUsername | BIG-IP Template | string | BIG-IP user name |
| bigIpInstance01VmId | BIG-IP Template | string | Virtual Machine resource ID |
| bigIpInstance02VmId | BIG-IP Template | string | Virtual Machine resource ID |
| vip1PrivateIp | Application Template | string | Service (VIP) Private IP Address |
| vip1PrivateUrlHttp | Application Template | string | Service (VIP) Private HTTP URL |
| vip1PrivateUrlHttps | Application Template | string | Service (VIP) Private HTTPS URL |
| vip1PublicIp | Dag Template | string | Service (VIP) Public IP Address |
| vip1PublicIpDns | Dag Template | string | Service (VIP) Public DNS |
| vip1PublicUrlHttp | Dag Template | string | Service (VIP) Public HTTP URL | 
| vip1PublicUrlHttps | Dag Template | string | Service (VIP) Public HTTPS URL |
| virtualNetworkId | Network Template | string | Virtual Network resource ID |
| wafPublicIps | Dag Template | array | External Public IP Addresses |


### Existing Network Template Input Parameters

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| artifactLocation | No | "f5-azure-arm-templates-v2/v2.0.0.0/examples/" | string | The directory, relative to the templateBaseUrl, where the modules folder is located. |
| bigIpImage | No | "f5-networks:f5-big-ip-best:f5-big-best-plus-hourly-25mbps:16.1.202000" | string | Two formats accepted. `URN` of the image to use in Azure marketplace or `ID` of custom image. Example URN value: `f5-networks:f5-big-ip-best:f5-big-best-plus-hourly-25mbps:16.1.202000`. You can find the URNs of F5 marketplace images in the README for this template or by running the command: `az vm image list --output yaml --publisher f5-networks --all`. See https://clouddocs.f5.com/cloud/public/v1/azure/Azure_download.html for information on creating custom BIG-IP image. |
| bigIpInstanceType | No | "Standard_D8s_v4" | string | Enter a valid instance type. |
| bigIpPasswordSecretId | Yes |  | string | The full URL of the secretId where the BIG-IP password is stored, including KeyVault Name. For example: https://yourvaultname.vault.azure.net/secrets/yoursecretid. This will be used by the BIG-IP to cluster with other devices. |
| bigIpRuntimeInitConfig01 | No | https://raw.githubusercontent.com/F5Networks/f5-azure-arm-templates-v2/v2.0.0.0/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance01.yaml | string | Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format, or an escaped JSON string to use for f5-bigip-runtime-init configuration. |
| bigIpRuntimeInitConfig02 | No | https://raw.githubusercontent.com/F5Networks/f5-azure-arm-templates-v2/v2.0.0.0/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance02.yaml | string | Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format, or an escaped JSON string to use for f5-bigip-runtime-init configuration. |
| bigIpRuntimeInitPackageUrl | No | https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.4.1/dist/f5-bigip-runtime-init-1.4.1-1.gz.run | string | Supply a URL to the bigip-runtime-init package. |
| cfeStorageAccountName | Yes |  | string | CFE storage account created and used for cloud-failover-extension. |
| cfeTag | No | "bigip_high_availability_solution" | string | Cloud Failover deployment tag value. |
| bigIpExternalSubnetId | Yes |  | string | Supply the Azure resource ID of the management subnet where BIG-IP VE instances will be deployed. |
| bigIpInternalSubnetId | Yes |  | string | Supply the Azure resource ID of the external subnet where BIG-IP VE instances will be deployed. |
| bigIpMgmtSubnetId | Yes |  | string | Supply the Azure resource ID of the internal subnet where BIG-IP VE instances will be deployed. |
| bigIpExternalSelfIp01 | No | "10.0.1.11" | string | External Private IP Address for BIGIP Instance 01. IP address parameter must be in the form x.x.x.x. |
| bigIpExternalSelfIp02 | No | "10.0.1.12" | string | External Private IP Address for BIGIP Instance 02. IP address parameter must be in the form x.x.x.x. |
| bigIpExternalVip01 | No | "10.0.1.101" | string | External private VIP Address for BIGIP Instance. IP address parameter must be in the form x.x.x.x. The address must reside in the same subnet and address space as the IP address provided for bigIpExternalSelfIp01. |
| bigIpInternalSelfIp01 | No | "10.0.2.11" | string | Internal Private IP Address for BIGIP Instance 01. IP address parameter must be in the form x.x.x.x. |
| bigIpInternalSelfIp02 | No | "10.0.2.12" | string | Internal Private IP Address for BIGIP Instance 02. IP address parameter must be in the form x.x.x.x. |
| bigIpMgmtAddress01 | No | "10.0.0.11" | string | Management Private IP Address for BIGIP Instance 01. IP address parameter must be in the form x.x.x.x. |
| bigIpMgmtAddress02 | No | "10.0.0.12" | string | Management Private IP Address for BIGIP Instance 02. IP address parameter must be in the form x.x.x.x. |
| bigIpPeerAddr | No | "10.0.1.11" | string | Type the static self IP address of the remote host here. Leave empty if not configuring peering with a remote host on this device. |
| provisionPublicIpMgmt | No | false | boolean | Select true if you would like to provision a public IP address for accessing the BIG-IP instance(s). |
| provisionServicePublicIp | No | false | boolean | Flag to deploy public IP address resource for application. |
| restrictedSrcAddressApp | Yes |  | string | An IP address range (CIDR) that can be used to restrict access web traffic (80/443) to the BIG-IP instances, for example 'X.X.X.X/32' for a host, '0.0.0.0/0' for the Internet, etc. **NOTE**: The VPC CIDR is automatically added for internal use. |
| restrictedSrcAddressMgmt | Yes |  | string | An IP address or address range (in CIDR notation) used to restrict SSH and management GUI access to the BIG-IP Management or bastion host instances. **Important**: The VPC CIDR is automatically added for internal use (access via bastion host, clustering, etc.). Please do NOT use "0.0.0.0/0". Instead, restrict the IP address range to your client or trusted network, for example "55.55.55.55/32". Production should never expose the BIG-IP Management interface to the Internet. |
| sshKey | Yes |  | string | Supply the public key that will be used for SSH authentication to the BIG-IP and application virtual machines. Note: This should be the public key as a string, typically starting with **ssh-rsa**. |
| tagValues | No | "application": "APP", "cost": "COST", "environment": "ENV", "group": "GROUP", "owner": "OWNER" | object | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique adjust them as needed for each key. |
| templateBaseUrl | No | https://cdn.f5.com/product/cloudsolutions/ | string | The publicly accessible URL where the linked ARM templates are located. |
| uniqueString | Yes |  | string | A prefix that will be used to name template resources. Because some resources require globally unique names, we recommend using a unique value. |
| useAvailabilityZones | No | false | boolean | This deployment can deploy resources into Azure Availability Zones (if the region supports it). If that is not desired the input should be set false. If the region does not support availability zones the input should be set to false. |
| userAssignManagedIdentity | No |  | string | Enter user-assigned pre-existing management identity ID to be associated to Virtual Machine Scale Set. If not specified, a new identity will be created. |


### Existing Network Template Outputs

| Name | Required Resource | Type | Description |
| --- | --- | --- | --- |
| bigIpInstance01ManagementPublicIp | BIG-IP Template | string | Management Private IP Address |
| bigIpInstance01ManagementPrivateIp | BIG-IP Template | string | Management Private IP Address |
| bigIpInstance01ManagementPublicUrl | Dag Template | string | Management Public IP Address |
| bigIpInstance01ManagementPrivateUrl | Dag Template | string | Management Public IP Address |
| bigIpInstance02ManagementPublicIp | BIG-IP Template | string | Management Private IP Address |
| bigIpInstance02ManagementPrivateIp | BIG-IP Template | string | Management Private IP Address |
| bigIpInstance02ManagementPublicUrl | Dag Template | string | Management Public IP Address |
| bigIpInstance02ManagementPrivateUrl | Dag Template | string | Management Public IP Address |
| bigIpUsername | BIG-IP Template | string | BIG-IP user name |
| bigIpInstance01VmId | BIG-IP Template | string | Virtual Machine resource ID |
| bigIpInstance02VmId | BIG-IP Template | string | Virtual Machine resource ID |
| vip1PrivateIp | Service Private IP Address | string | Service (VIP) Private IP Address |
| vip1PrivateUrlHttp | Service Private IP Address| string | Service (VIP) Private HTTP URL |
| vip1PrivateUrlHttps | Service Private IP Address| string | Service (VIP) Private HTTPS URL |
| vip1PublicIp | Dag Template | string | Service (VIP) Public IP Address |
| vip1PublicIpDns | Dag Template | string | Service (VIP) Public DNS |
| vip1PublicUrlHttp | Dag Template | string | Service (VIP) Public HTTP URL |
| vip1PublicUrlHttps | Dag Template | string | Service (VIP) Public HTTPS URL |
| wafPublicIps | Dag Template | array | External Public IP Addresses |

## Deploying this Solution

Two options for deploying this solution include:

- Using the [Azure deploy button](#deploying-via-the-azure-deploy-button) - in the Azure Portal
- Using [CLI Tools](#deploying-via-the-azure-cli)

### Deploying via the Azure Deploy button

The easiest way to deploy this Azure Arm templates is to use the deploy button below:<br>

**Full Stack**
[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FF5Networks%2Ff5-azure-arm-templates-v2%2Fv2.3.0.0%2Fexamples%2Ffailover%2Fazuredeploy.json)

**Existing Stack**
[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FF5Networks%2Ff5-azure-arm-templates-v2%2Fv2.3.0.0%2Fexamples%2Ffailover%2Fazuredeploy-existing-network.json)

*Step 1: Custom Template Page* 
  - Select or Create New Resource Group.
  - Fill in the *REQUIRED* parameters (with * next to them). 
    - **sshKey**
    - **restrictedSrcAddressApp**
    - **restrictedSrcAddressMgmt**
    - **uniqueString**
    - **cfeStorageAccountName**
  - Click "Next: Review + Create".

*Step 2: Custom Template Page*
  After "Validation Passed" click "Create".

For next steps, see [Validating the Deployment](#validating-the-deployment).

### Deploying via the Azure CLI

As an alternative to deploying through the Azure Portal (GUI), each solution provides an example Azure CLI 2.0 command to deploy the ARM template. The following example deploys a HA pair of 3-NIC BIG-IP VE instances.

#### Azure CLI (2.0) Script Example

*NOTE: First replace parameter values with `<YOUR_VALUE>` with your values.*

```bash
RESOURCE_GROUP="myGroupName"
REGION="eastus"
DEPLOYMENT_NAME="parentTemplate"
TEMPLATE_URI="https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v2.3.0.0/examples/failover/azuredeploy.json"
DEPLOY_PARAMS='{"templateBaseUrl":{"value":"https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/"},"artifactLocation":{"value":"v2.3.0.0/examples/"},"uniqueString":{"value":"<YOUR_VALUE>"},"sshKey":{"value":"<YOUR_VALUE>"},"cfeStorageAccountName":{"value":"<YOUR_VALUE>"},"bigIpInstanceType":{"value":"Standard_D8s_v4"},"bigIpImage":{"value":"f5-networks:f5-big-ip-best:f5-big-best-plus-hourly-25mbps:16.1.202000"},"appContainerName":{"value":"f5devcentral/f5-demo-app:latest"},"restrictedSrcAddressMgmt":{"value":"<YOUR_VALUE>"},"restrictedSrcAddressApp":{"value":"<YOUR_VALUE>"},"restrictedSrcAddressVip":{"value":"<YOUR_VALUE>"},"bigIpRuntimeInitConfig01":{"value":"https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v2.3.0.0/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance01-with-app.yaml"},"bigIpRuntimeInitConfig02":{"value":"https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v2.3.0.0/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance02-with-app.yaml"},"useAvailabilityZones":{"value":false}}'
DEPLOY_PARAMS_FILE=deploy_params.json
echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}
az group create -n ${RESOURCE_GROUP} -l ${REGION}
az deployment group create --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} --template-uri ${TEMPLATE_URI}  --parameters @${DEPLOY_PARAMS_FILE}
```

When deploying **azuredeploy-existing-network.json**, modify the deployment parameters to match the requirements specified in the **Existing Network Template Input Parameters** table above.

For next steps, see [Validating the Deployment](#validating-the-deployment).


### Changing the BIG-IP Deployment

You will most likely want or need to change the BIG-IP configuration. This generally involves referencing or customizing a [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) configuration file and passing it through the **bigIpRuntimeInitConfig01** and **bigIpRuntimeInitConfig02** template parameters as a URL or inline json. 

Example from azuredeploy.parameters.json
```json
    "useAvailabilityZones": {
        "value": false
    },
    "bigIpRuntimeInitConfig01": {
        "value": "https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v2.3.0.0/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance01.yaml"
    },
    "bigIpRuntimeInitConfig02": {
        "value": "https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v2.3.0.0/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance02.yaml"
    },
```

**IMPORTANT**: Note the "raw.githubusercontent.com". Any URLs pointing to github **must** use the raw file format. 

The F5 BIG-IP Runtime Init configuration file can also be formatted in json and/or passed directly inline:

```json
    "useAvailabilityZones": {
        "value": false
    },
    "bigIpRuntimeInitConfig01": {
        "value": "{\"extension_packages\":{\"install_operations\":[{\"extensionType\":\"do\",\"extensionVersion\":\"1.25.0\",\"extensionHash\":\"2c990f6185b16acf0234ebba02afc24863f538c955f51c7a3ebe01d5db58b859\"},{\"extensionType\":\"as3\",\"extensionVersion\":\"3.32.0\",\"extensionHash\":\"a0746531a70b86316a68ab1eb9b3be5b18606f1bf0032ddc5c41a01c32d452a7\"},{\"extensionType\":\"cf\",\"extensionVersion\":\"1.9.0\",\"extensionHash\":\"da3118eacc4fe9ff925d95d4bf8d1993810560e07260825306cb0721862defdf\"}]},\"extension_services\":{\"service_operations\":[{\"extensionType\":\"do\",\"type\":\"inline\",\"value\":{\"schemaVersion\":\"1.0.0\",\"class\":\"Device\",\"async\":true,\"label\":\"Standalone3NICBIG-IPdeclarationforDeclarativeOnboardingwithPAYGlicense\",\"Common\":{\"class\":\"Tenant\",\"My_DbVariables\":{\"class\":\"DbVariables\",\"provision.extramb\":1000,\"restjavad.useextramb\":true,\"dhclient.mgmt\":\"disable\",\"config.allow.rfc3927\":\"enable\",\"tm.tcpudptxchecksum\":\"Software-only\"},\"My_Provisioning\":{\"class\":\"Provision\",\"ltm\":\"nominal\"},\"my_Ntp\":{\"class\":\"NTP\",\"servers\":[\"0.pool.ntp.org\",\"1.pool.ntp.org\"],\"timezone\":\"UTC\"},\"My_Dns\":{\"class\":\"DNS\",\"nameServers\":[\"168.63.129.16\"]},\"my_System\":{\"autoPhonehome\":true,\"class\":\"System\",\"hostname\":\"failover0.local\"},\"admin\":{\"class\":\"User\",\"userType\":\"regular\",\"password\":\"{{{BIGIP_PASSWORD}}}\",\"shell\":\"bash\"},\"default\":{\"class\":\"ManagementRoute\",\"gw\":\"10.0.0.1\",\"network\":\"default\"},\"dhclient_route1\":{\"class\":\"ManagementRoute\",\"gw\":\"10.0.0.1\",\"network\":\"168.63.129.16/32\"},\"azureMetadata\":{\"class\":\"ManagementRoute\",\"gw\":\"10.0.0.1\",\"network\":\"169.254.169.254/32\"},\"defaultRoute\":{\"class\":\"Route\",\"gw\":\"10.0.1.1\",\"network\":\"default\",\"mtu\":1500},\"external\":{\"class\":\"VLAN\",\"tag\":4094,\"mtu\":1500,\"interfaces\":[{\"name\":\"1.1\",\"tagged\":false}]},\"externalSelf\":{\"class\":\"SelfIp\",\"address\":\"{{{SELF_IP_EXTERNAL}}}\",\"vlan\":\"external\",\"allowService\":\"default\",\"trafficGroup\":\"traffic-group-local-only\"},\"internal\":{\"class\":\"VLAN\",\"interfaces\":[{\"name\":\"1.2\",\"tagged\":false}],\"mtu\":1500,\"tag\":4093},\"internal-self\":{\"class\":\"SelfIp\",\"address\":\"{{{SELF_IP_INTERNAL}}}\",\"vlan\":\"internal\",\"allowService\":\"default\",\"trafficGroup\":\"traffic-group-local-only\"},\"configSync\":{\"class\":\"ConfigSync\",\"configsyncIp\":\"/Common/externalSelf/address\"},\"failoverAddress\":{\"class\":\"FailoverUnicast\",\"address\":\"/Common/externalSelf/address\"},\"failoverGroup\":{\"class\":\"DeviceGroup\",\"type\":\"sync-failover\",\"members\":[\"failover0.local\",\"failover1.local\"],\"owner\":\"/Common/failoverGroup/members/0\",\"autoSync\":true,\"saveOnAutoSync\":false,\"networkFailover\":true,\"fullLoadOnSync\":false,\"asmSync\":false},\"trust\":{\"class\":\"DeviceTrust\",\"localUsername\":\"admin\",\"localPassword\":\"{{{BIGIP_PASSWORD}}}\",\"remoteHost\":\"/Common/failoverGroup/members/0\",\"remoteUsername\":\"admin\",\"remotePassword\":\"{{{BIGIP_PASSWORD}}}\"}}}},{\"extensionType\":\"cf\",\"type\":\"inline\",\"value\":{\"schemaVersion\":\"1.0.0\",\"class\":\"Cloud_Failover\",\"environment\":\"azure\",\"controls\":{\"class\":\"Controls\",\"logLevel\":\"info\"},\"externalStorage\":{\"scopingTags\":{\"f5_cloud_failover_label\":\"bigip_high_availability_solution\"}},\"failoverAddresses\":{\"enabled\":true,\"scopingTags\":{\"f5_cloud_failover_label\":\"bigip_high_availability_solution\"},\"requireScopingTags\":false}}}]},\"post_onboard_enabled\":[],\"pre_onboard_enabled\":[{\"name\":\"disable_1nic_config\",\"type\":\"inline\",\"commands\":[\"/usr/bin/setdbprovision.1nicautoconfigdisable\"]},{\"name\":\"provision_rest\",\"type\":\"inline\",\"commands\":[\"/usr/bin/setdbprovision.extramb1000\",\"/usr/bin/setdbrestjavad.useextrambtrue\"]}],\"runtime_parameters\":[{\"name\":\"BIGIP_PASSWORD\",\"type\":\"secret\",\"secretProvider\":{\"type\":\"KeyVault\",\"environment\":\"azure\",\"vaultUrl\":\"https://yourvaultname.vault.azure.net\",\"secretId\":\"mySecretId\"}},{\"name\":\"SELF_IP_EXTERNAL\",\"type\":\"metadata\",\"metadataProvider\":{\"type\":\"network\",\"environment\":\"azure\",\"field\":\"ipv4\",\"index\":1}},{\"name\":\"SELF_IP_INTERNAL\",\"type\":\"metadata\",\"metadataProvider\":{\"type\":\"network\",\"environment\":\"azure\",\"field\":\"ipv4\",\"index\":2}}]}"
    },
    "bigIpRuntimeInitConfig02": {
        "value": "{\"extension_packages\":{\"install_operations\":[{\"extensionType\":\"do\",\"extensionVersion\":\"1.25.0\",\"extensionHash\":\"2c990f6185b16acf0234ebba02afc24863f538c955f51c7a3ebe01d5db58b859\"},{\"extensionType\":\"as3\",\"extensionVersion\":\"3.32.0\",\"extensionHash\":\"a0746531a70b86316a68ab1eb9b3be5b18606f1bf0032ddc5c41a01c32d452a7\"},{\"extensionType\":\"cf\",\"extensionVersion\":\"1.9.0\",\"extensionHash\":\"da3118eacc4fe9ff925d95d4bf8d1993810560e07260825306cb0721862defdf\"}]},\"extension_services\":{\"service_operations\":[{\"extensionType\":\"do\",\"type\":\"inline\",\"value\":{\"schemaVersion\":\"1.0.0\",\"class\":\"Device\",\"async\":true,\"label\":\"Standalone3NICBIG-IPdeclarationforDeclarativeOnboardingwithPAYGlicense\",\"Common\":{\"class\":\"Tenant\",\"My_DbVariables\":{\"class\":\"DbVariables\",\"provision.extramb\":1000,\"restjavad.useextramb\":true,\"dhclient.mgmt\":\"disable\",\"config.allow.rfc3927\":\"enable\",\"tm.tcpudptxchecksum\":\"Software-only\"},\"My_Provisioning\":{\"class\":\"Provision\",\"ltm\":\"nominal\"},\"my_Ntp\":{\"class\":\"NTP\",\"servers\":[\"0.pool.ntp.org\",\"1.pool.ntp.org\"],\"timezone\":\"UTC\"},\"My_Dns\":{\"class\":\"DNS\",\"nameServers\":[\"168.63.129.16\"]},\"my_System\":{\"autoPhonehome\":true,\"class\":\"System\",\"hostname\":\"failover1.local\"},\"admin\":{\"class\":\"User\",\"userType\":\"regular\",\"password\":\"{{{BIGIP_PASSWORD}}}\",\"shell\":\"bash\"},\"default\":{\"class\":\"ManagementRoute\",\"gw\":\"10.0.0.1\",\"network\":\"default\"},\"dhclient_route1\":{\"class\":\"ManagementRoute\",\"gw\":\"10.0.0.1\",\"network\":\"168.63.129.16/32\"},\"azureMetadata\":{\"class\":\"ManagementRoute\",\"gw\":\"10.0.0.1\",\"network\":\"169.254.169.254/32\"},\"defaultRoute\":{\"class\":\"Route\",\"gw\":\"10.0.1.1\",\"network\":\"default\",\"mtu\":1500},\"external\":{\"class\":\"VLAN\",\"tag\":4094,\"mtu\":1500,\"interfaces\":[{\"name\":\"1.1\",\"tagged\":false}]},\"externalSelf\":{\"class\":\"SelfIp\",\"address\":\"{{{SELF_IP_EXTERNAL}}}\",\"vlan\":\"external\",\"allowService\":\"default\",\"trafficGroup\":\"traffic-group-local-only\"},\"internal\":{\"class\":\"VLAN\",\"interfaces\":[{\"name\":\"1.2\",\"tagged\":false}],\"mtu\":1500,\"tag\":4093},\"internal-self\":{\"class\":\"SelfIp\",\"address\":\"{{{SELF_IP_INTERNAL}}}\",\"vlan\":\"internal\",\"allowService\":\"default\",\"trafficGroup\":\"traffic-group-local-only\"},\"configSync\":{\"class\":\"ConfigSync\",\"configsyncIp\":\"/Common/externalSelf/address\"},\"failoverAddress\":{\"class\":\"FailoverUnicast\",\"address\":\"/Common/externalSelf/address\"},\"failoverGroup\":{\"class\":\"DeviceGroup\",\"type\":\"sync-failover\",\"members\":[\"failover0.local\",\"failover1.local\"],\"owner\":\"/Common/failoverGroup/members/0\",\"autoSync\":true,\"saveOnAutoSync\":false,\"networkFailover\":true,\"fullLoadOnSync\":false,\"asmSync\":false},\"trust\":{\"class\":\"DeviceTrust\",\"localUsername\":\"admin\",\"localPassword\":\"{{{BIGIP_PASSWORD}}}\",\"remoteHost\":\"10.0.1.11\",\"remoteUsername\":\"admin\",\"remotePassword\":\"{{{BIGIP_PASSWORD}}}\"}}}},{\"extensionType\":\"cf\",\"type\":\"inline\",\"value\":{\"schemaVersion\":\"1.0.0\",\"class\":\"Cloud_Failover\",\"environment\":\"azure\",\"controls\":{\"class\":\"Controls\",\"logLevel\":\"info\"},\"externalStorage\":{\"scopingTags\":{\"f5_cloud_failover_label\":\"bigip_high_availability_solution\"}},\"failoverAddresses\":{\"enabled\":true,\"scopingTags\":{\"f5_cloud_failover_label\":\"bigip_high_availability_solution\"},\"requireScopingTags\":false}}}]},\"post_onboard_enabled\":[],\"pre_onboard_enabled\":[{\"name\":\"disable_1nic_config\",\"type\":\"inline\",\"commands\":[\"/usr/bin/setdbprovision.1nicautoconfigdisable\"]},{\"name\":\"provision_rest\",\"type\":\"inline\",\"commands\":[\"/usr/bin/setdbprovision.extramb1000\",\"/usr/bin/setdbrestjavad.useextrambtrue\"]}],\"runtime_parameters\":[{\"name\":\"BIGIP_PASSWORD\",\"type\":\"secret\",\"secretProvider\":{\"type\":\"KeyVault\",\"environment\":\"azure\",\"vaultUrl\":\"https://yourvaultname.vault.azure.net\",\"secretId\":\"mySecretId\"}},{\"name\":\"SELF_IP_EXTERNAL\",\"type\":\"metadata\",\"metadataProvider\":{\"type\":\"network\",\"environment\":\"azure\",\"field\":\"ipv4\",\"index\":1}},{\"name\":\"SELF_IP_INTERNAL\",\"type\":\"metadata\",\"metadataProvider\":{\"type\":\"network\",\"environment\":\"azure\",\"field\":\"ipv4\",\"index\":2}}]}"
    },
```

NOTE: If providing the json inline as a template parameter, you must escape all double quotes so it can be passed as a single parameter string.

*TIP: If you haven't forked/published your own repository or don't have an easy way to host your own config files, passing the config as inline json via the template input parameter might be the quickest / most accessible option to test out different BIG-IP configs using this repository.*

F5 has provided the following example configuration files in the `examples/failover/bigip-configurations` folder:

- These examples install Automation Tool Chain packages for a PAYG licensed deployment.
  - `runtime-init-conf-3nic-payg-instance01.yaml`
  - `runtime-init-conf-3nic-payg-instance02.yaml`
- These examples install Automation Tool Chain packages and create WAF-protected services for a PAYG licensed deployment.
  - `runtime-init-conf-3nic-payg-instance01-with-app.yaml`
  - `runtime-init-conf-3nic-payg-instance02-with-app.yaml`
- These examples install Automation Tool Chain packages for a BYOL licensed deployment.
  - `runtime-init-conf-3nic-byol-instance01.yaml`
  - `runtime-init-conf-3nic-byol-instance02.yaml`
- These examples install Automation Tool Chain packages and create WAF-protected services for a BYOL licensed deployment.
  - `runtime-init-conf-3nic-byol-instance01-with-app.yaml`
  - `runtime-init-conf-3nic-byol-instance02-with-app.yaml`
- `Rapid_Deployment_Policy_13_1.xml` - This ASM security policy is supported for BIG-IP 13.1 and later.

See [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) for more examples.

- When specifying values for the bigIpInstanceType parameter, ensure that the instance type you select is appropriate for the deployment scenario. See [Azure Virtual Machine Instance Types](https://docs.microsoft.com/en-us/azure/virtual-machines/dv2-dsv2-series) for more information.

However, most changes require modifying the configurations themselves. For example:

To deploy **BYOL** instances:

  1. Edit/modify the Declarative Onboarding (DO) declarations in a corresponding `byol` runtime-init config file with the new `regKey` value. 

Example:
```yaml
          My_License:
            class: License
            licenseType: regKey
            regKey: AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE
```
  2. Publish/host the customized runtime-init config files at a location reachable by the BIG-IP at deploy time (for example: github, Azure Storage, etc.)
  3. Update the **bigIpRuntimeInitConfig01** and **bigIpRuntimeInitConfig02** input parameters to reference the new URL of the updated configuration.
  4. Update the **bigIpImage** input parameter to use `byol` image.
        Example:
        ```json 
        "bigIpImage":{ 
          "value": "f5-networks:f5-big-ip-byol:f5-big-all-2slot-byol:16.0.101000" 
        }
        ```

In order deploy additional **virtual services**:

For illustration purposes, this solution pre-provisions IP addresses and the runtime-init configurations contain an AS3 declaration to create an example virtual service. However, in practice, cloud-init runs once and is typically used for initial provisioning, not as the primary configuration API for a long-running platform. More typically in an infrastructure use case, virtual services are not included in the initial cloud-init configuration are added post initial deployment which involves:
  1. *Cloud* - Provisioning additional IPs on the desired Network Interfaces. Examples:
      - [az network nic ip-config create](https://docs.microsoft.com/en-us/cli/azure/network/nic/ip-config?view=azure-cli-latest#az_network_nic_ip_config_create)
      - [az network public-ip create](https://docs.microsoft.com/en-us/cli/azure/network/public-ip?view=azure-cli-latest#az_network_public_ip_create)
      - [az network nic ip-config update](https://docs.microsoft.com/en-us/cli/azure/network/nic/ip-config?view=azure-cli-latest#az_network_nic_ip_config_update)
  2. *BIG-IP* - Creating Virtual Services that match those additional Secondary IPs 
      - Updating the [AS3](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/composing-a-declaration.html) declaration with additional Virtual Services (see **virtualAddresses:**).


*NOTE: For cloud resources, templates can be customized to pre-provision and update additional resources (for example: Private IPs, Public IPs, etc.). Please see [Getting Help](#getting-help) for more information. For BIG-IP configurations, you can leverage any REST or Automation Tool Chain clients like [Ansible](https://ansible.github.io/workshops/exercises/ansible_f5/3.0-as3-intro/),[Terraform](https://registry.terraform.io/providers/F5Networks/bigip/latest/docs/resources/bigip_as3),etc.*


## Validation

This section describes how to validate the template deployment, test the WAF service, and troubleshoot common problems.

### Validating the Deployment

To view the status of the example and module template deployments, navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments**. You should see a series of deployments, including the parent template as well as the linked templates, which can include: networkTemplate, accessTemplate, appTemplate, bastionTemplate, dagTemplate and bigIpTemplate. The deployment status for each template deployment should be "Succeeded". 

Expected Deploy time for entire stack =~ 8-10 minutes.

If any of the deployments are in a failed state, proceed to the [Troubleshooting Steps](#troubleshooting-steps) section below.

### Accessing the BIG-IP Instances

From Parent Template Outputs:
  - **Console**:  Navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments > *DEPLOYMENT_NAME* > Outputs**.
  - **Azure CLI**: 
    ```bash
    az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME}  -o tsv --query properties.outputs" 
    ```

- Obtain the public IP addresses of the BIG-IP Management Ports:
  - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments > *DEPLOYMENT_NAME* > Outputs > *bigIpInstance01ManagementPublicIp* and *bigIpInstance02ManagementPublicIp***.
  - **Azure CLI**: 
    ``` bash 
    az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} -o tsv --query properties.outputs.bigIpInstance01ManagementPublicIp.value
    az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} -o tsv --query properties.outputs.bigIpInstance02ManagementPublicIp.value
    ```

- Or if you are going through a bastion host (when **provisionPublicIpMgmt** = **false**):
  - Obtain the public IP address of the bastion host:
    - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments > *DEPLOYMENT_NAME* > Outputs > *bastionPublicIp***.
    - **Azure CLI**: 
    ``` bash 
    az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} -o tsv --query properties.outputs.bastionPublicIp.value
    ```


  - Obtain the private IP addresses of the BIG-IP Management Ports:
    - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments > *DEPLOYMENT_NAME* > Outputs > *bigIpInstance01ManagementPrivateIp* and *bigIpInstance02ManagementPrivateIp***.
    - **Azure CLI**: 
      ``` bash 
      az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} -o tsv --query properties.outputs.bigIpInstance01ManagementPrivateIp.value
      az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} -o tsv --query properties.outputs.bigIpInstance02ManagementPrivateIp.value
      ```


#### SSH
  
  - **SSH key authentication**: 
      ```bash
      ssh admin@${IP_ADDRESS_FROM_OUTPUT} -i ${YOUR_PRIVATE_SSH_KEY}
      ```
  - **Password authentication**: 
      ```bash 
      ssh admin@${IP_ADDRESS_FROM_OUTPUT}
      ``` 
      at prompt, enter the BIG-IP password from the Azure Key Vault secret you provided in the **bigIpPasswordSecretId** input.


    - OR if you are going through a bastion host (when **provisionPublicIpMgmt** = **false**):

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

1. Obtain the URL addresses of the BIG-IP Management Ports:
  - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments > *DEPLOYMENT_NAME* > Outputs > bigIpInstance01ManagementPublicUrl and bigIpInstance02ManagementPublicUrl**.
  - **Azure CLI**: 
    ```bash
    az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME}  -o tsv --query properties.outputs.bigIpInstance01ManagementPublicUrl.value
    az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME}  -o tsv --query properties.outputs.bigIpInstance02ManagementPublicUrl.value
    ```

  - OR when you are going through a bastion host (when **provisionPublicIpMgmt** = **false**):
    - From your desktop client/shell, create an SSH tunnel:

        ```bash
        ssh -i [your-private-ssh-key.pem] [AZURE-USER]@[BASTION-HOST-PUBLIC-IP] -L 8443:[BIG-IP-MGMT-PRIVATE-IP]:[BIGIP-GUI-PORT]
        ```
        For example:
        ```bash
        ssh -i ~/.ssh/mykey.pem azureuser@34.82.102.190 -L 8443:10.0.0.11:443
        ```

        NOTE: `[BIGIP-GUI-PORT]` is 443 for multi-NIC deployments and 8443 for single-NIC deployments.

        You should now be able to open a browser to the BIG-IP UI from your desktop:

        https://localhost:8443



2. Open a browser to the Management URL.
  - *NOTE: By default, the BIG-IP system's WebUI starts with a self-signed cert. Follow your browser's instructions for accepting self-signed certs (for example, if using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click "Advanced" button, click "Accept Risk and Continue").*
  - To Login: 
    - username: admin
    - password: enter the BIG-IP password from the Azure Key Vault secret you provided in the **bigIpPasswordSecretId** input.


### Further Exploring

#### WebUI

 - When **provisionExampleApp** is **true**, Navigate to **Virtual Services > Partition**. Select **Partition = `Tenant_1`**
    - Navigate to **Local Traffic > Virtual Servers**. You should see two Virtual Services (one for HTTP and one for HTTPS). The should show up as Green. Click on them to look at the configuration *(declared in the AS3 declaration)*

#### SSH

  - From tmsh shell, type 'bash' to enter the bash shell:
    - Examine BIG-IP configuration via [F5 Automation Toolchain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) declarations:
    ```bash
    curl -u admin: http://localhost:8100/mgmt/shared/declarative-onboarding | jq .
    ```
    - If you deployed the example application (**provisionExampleApp** = **true**), examine the Application Services declaration:
    ```bash
    curl -u admin: http://localhost:8100/mgmt/shared/appsvcs/declare | jq .
    ```
    - Exampine the BIG-IP [Cloud Failover Extension (CFE)](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/) declaration:
    ```bash
    curl -su admin: http://localhost:8100/mgmt/shared/cloud-failover/declare | jq . 
    ```
    - Examine the [Runtime-Init](https://github.com/F5Networks/f5-bigip-runtime-init) Config downloaded: 
    ```bash 
    cat /config/cloud/runtime-init.conf
    ```

### Testing the WAF Service

When **provisionExampleApp** is **true**, to test the WAF service, perform the following steps:
- Obtain the IP address of the WAF service:
  - **Console**: Navigate to **Resource Groups > *RESOURCE_GROUP* > Deployments > *DEPLOYMENT_NAME* > Outputs > vip1PublicIp**.
  - **Azure CLI**: 
      ```bash
      az deployment group show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} -o tsv --query properties.outputs.vip1PublicIp.value
      ```
- Verify the application is responding:
  - Paste the IP address in a browser: ```https://${IP_ADDRESS_FROM_OUTPUT}```
      - NOTE: By default, the Virtual Service starts with a self-signed cert. Follow your browsers instructions for accepting self-signed certs (for example, if using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click the "Advanced" button, click "Accept Risk and Continue", etc.).
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

### Testing Failover

 When **provisionExampleApp** is **true**, to test failover, perform the following steps:

1. Log on the BIG-IPs per instructions above:

  - **WebUI**: Go to Device Management of Active Instance -> Traffic-Groups -> Select box next to *traffic-group-1* -> Click the "Force to Standby" button *.
  - **BIG-IP CLI**: 
      ```bash 
      tmsh run sys failover standby
      ```

Verify the IPs associated w/ the Virtual Service (**vip1PrivateIp** and **vip1PublicIp**) is remapped to the peer BIG-IP's external NIC. 
  - **Console**: Navigate to  **Resource Groups > *RESOURCE_GROUP* > Overview > *BIGIP* Virtual Machines > Networking > external-nic > IP Configurations**

For information on the Cloud Failover solution, see [F5 Cloud Failover Extension](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/azure.html).

## Deleting this Solution

### Deleting the deployment via Azure Portal 

1. Navigate to **Home** > Select "Resource Groups" Icon.

2. Select your Resource Group by clicking the link.

3. Click **Delete Resource Group**.

4. Type the name of the Resource Group when prompted to confirm.

5. Click **Delete**.

### Deleting the deployment using the Azure CLI

```bash
az group delete -n ${RESOURCE_GROUP}
```


## Troubleshooting Steps

There are generally two classes of issues:

1. Template deployment itself failed
2. Resource(s) within the template failed to deploy

To verify that all templates deployed successfully, follow the instructions under **Validating the Deployment** above to locate the failed deployment(s).

Click on the name of a failed deployment and then click **Events**. Click the link in the red banner at the top of the deployment overview for details about the failure cause. 

Additionally, if the template passed validation but individual template resources have failed to deploy, you can see more information by expanding Deployment Details, then clicking on the Operation details column for the failed resource. **When creating a GitHub issue for a template, please include as much information as possible from the failed Azure deployment/resource events.**

Common deployment failure causes include:
- Required fields were left empty or contained incorrect values (input type mismatch, prohibited characters, malformed JSON, etc.) causing template validation failure.
- Insufficient permissions to create the deployment or resources created by a deployment.
- Resource limitations (exceeded limit of IP addresses or compute resources, etc.).
- Azure service issues (these will usually surface as 503 internal server errors in the deployment status error message).

If all deployments completed "successfully" but maybe the BIG-IP or Service is not reachable, then log in to the BIG-IP instance via SSH to confirm BIG-IP deployment was successful (for example, if startup scripts completed as expected on the BIG-IP). To verify BIG-IP deployment, perform the following steps:
- Obtain the IP address of the BIG-IP instance. See instructions [above](#accessing-the-bigip-ip)
- Check startup-script to make sure was installed/interpolated correctly:
  - ```cat /var/lib/waagent/CustomData  | base64 -d```
- Check the logs (in order of invocation):
  - waagent logs:
    - */var/log/waagent.log*
  - cloud-agent logs:
    - */var/log/boot.log*
    - */var/log/cloud-init.log*
    - */var/log/cloud-init-output.log*
  - runtime-init Logs:
    - */var/log/cloud/startup-script.log*: This file contains events that happen prior to execution of f5-bigip-runtime-init. If the files required by the deployment fail to download, for example, you will see those events logged here.
    - */var/log/cloud/bigipRuntimeInit.log*: This file contains events logged by the f5-bigip-runtime-init onboarding utility. If the configuration is invalid causing onboarding to fail, you will see those events logged here. If deployment is successful, you will see an event with the body "All operations completed successfully".
  - Automation Tool Chain Logs:
    - */var/log/restnoded/restnoded.log*: This file contains events logged by the F5 Automation Toolchain components. If an Automation Toolchain declaration fails to deploy, you will see more details for those events logged here.
- *GENERAL LOG TIP*: Search most critical error level errors first (for example, egrep -i err /var/log/<Logname>).

If you are unable to login to the BIG-IP instance(s), you can navigate to **Resource Groups > *RESOURCE_GROUP* > Overview > *INSTANCE_NAME* > Support and Troubleshooting > Serial console** for additional information from Azure.


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

If you want to verify the integrity of the template itself, F5 provides checksums for all of our templates. For instructions and the checksums to compare against, see [checksums-for-f5-supported-cft-and-arm-templates-on-github](https://community.f5.com/t5/crowdsrc/checksums-for-f5-supported-cloud-templates-on-github/ta-p/284471).

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
| 16.1.202000 | 16.1.2.2 Build 0.0.28 |
| 14.1.406000 | 14.1.4.6 Build 0.0.8 |


## Supported Instance Types and Hypervisors

- For a list of supported Azure instance types for this solution, see the [Azure instances for BIG-IP VE](http://clouddocs.f5.com/cloud/public/v1/azure/Azure_singleNIC.html#azure-instances-for-big-ip-ve).

- For a list of versions of the BIG-IP Virtual Edition (VE) and F5 licenses that are supported on specific hypervisors and Microsoft Azure, see [supported-hypervisor-matrix](https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ve-supported-hypervisor-matrix.html).


## Documentation

For information on getting started using F5's ARM templates on GitHub, see [Microsoft Azure: Solutions 101](http://clouddocs.f5.com/cloud/public/v1/azure/Azure_solutions101.html).

For more information on F5 solutions for Azure, including manual configuration procedures for some deployment scenarios, see the Azure section of [Public Cloud Docs](http://clouddocs.f5.com/cloud/public/v1/).


## Getting Help

Due to the heavy customization requirements of external cloud resources and BIG-IP configurations in these solutions, F5 does not provide technical support for deploying, customizing, or troubleshooting the templates themselves. However, the various underlying products and components used (for example: [F5 BIG-IP Virtual Edition](https://clouddocs.f5.com/cloud/public/v1/), [F5 BIG-IP Runtime Init](https://github.com/F5Networks/f5-bigip-runtime-init), [F5 Automation Toolchain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) extensions, and [Cloud Failover Extension (CFE)](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/)) in the solutions located here are F5-supported and capable of being deployed with other orchestration tools. Read more about [Support Policies](https://www.f5.com/company/policies/support-policies). Problems found with the templates deployed as-is should be reported via a GitHub issue.

For help with authoring and support for custom CST2 templates, we recommend engaging F5 Professional Services (PS).

### Filing Issues

Use the **Issues** link on the GitHub menu bar in this repository for items such as enhancement or feature requests and bugs found when deploying the example templates as-is. Tell us as much as you can about what you found and how you found it.