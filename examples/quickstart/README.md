# Deploying the BIG-IP VE in Azure - Example Quickstart BIG-IP WAF (LTM + ASM) - Virtual Machine

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)

## Contents

- [Example Quickstart - BIG-IP Virtual Edition with WAF (LTM + ASM)](#example-quickstart---big-ip-virtual-edition-with-waf--ltm---asm-)
  - [Introduction](#introduction)
  - [Diagram](#diagram)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Deploying this Solution](#deploying-this-solution)
    - [Deploying via the Azure Deploy button](#deploying-via-the-azure-deploy-button)
    - [Deploying via the Azure CLI](#deploying-via-the-azure-cli)
    - [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment)
  - [Validation](#validation)
    - [Validating the Deployment](#validating-the-deployment)
    - [Testing the WAF Service](#testing-the-waf-service)
  - [Deleting this Solution](#deleting-this-solution)
  - [Troubleshooting Steps](#troubleshooting-steps)
  - [Security](#security)
  - [BIG-IP Versions](#big-ip-versions)
  - [Supported Instance Types and Hypervisors](#supported-instance-types-and-hypervisors)
  - [Documentation](#documentation)
  - [Getting Help](#getting-help)
    - [Filing Issues](#filing-issues)


## Introduction

The goal of this solution is to reduce prerequisits and complexity to a minimum so with a few clicks, a user can quickly deploy a BIG-IP, login and begin exploring the BIG-IP platform in a working full-stack deployment capable of passing traffic. 

This solution uses a parent template to launch several linked child templates (modules) to create a full example stack for the BIG-IP. The linked templates are located in the `examples/modules` directory in this repository. *F5 encourages you to clone this repository and modify these templates to fit your use case.*


The modules below create the following cloud resources:

- **Network**: This template creates Azure Virtual Networks, Subnets, and Route Tables.
- **Application**: This template creates a generic example application for use when demonstrating live traffic through the BIG-IP instance.
- **Disaggregation** *(DAG/Ingress)*: This template creates resources required to get traffic to the BIG-IP, including Network Security Groups, Public IP Addresses, NAT rules and probes.
- **BIG-IP**: This template creates an F5 BIG-IP Virtual Edition provisioned with Local Traffic Manager (LTM) and Application Security Manager (ASM). 

By default, this solution creates a Vnet with four subnets, an example Web Application instance and a PAYG BIG-IP instance with three network interfaces (one for management and two for dataplane/application traffic - called external and internal).  Application traffic from the Internet traverses an external network interface configured with both public and private IP addresses. Traffic to the application traverses an internal network interface configured with a private IP address.

***DISCLAIMER/WARNING***: To reduce prerequisits and complexity to a bare minimum for evaluation purposes only, this quickstart provides immediate access to the management interface via a Public IP.  At the very *minimum*, configure the **restrictedSrcAddressMgmt** parameter to limit access to your client IP or trusted network.  In production deployments, management access should never be directly exposed to the Internet and instead should be accessed via typical managment best practices like jumpboxes/bastion hosts, vpns, etc.  


## Diagram

![Configuration Example](https://github.com/F5Networks/f5-azure-arm-templates-v2/blob/master/examples/quickstart/diagram.png)


## Prerequisites

  - This solution requires an SSH public key for access to the BIG-IP instances.
  - This solution requires an Azure account that can provision objects described in the solution.
  - This solution requires you to accept any Azure Marketplace "License/Terms and Conditions" for the images used in this solution.
    - By default, this solution uses [F5 BIG-IP Virtual Edition - BEST (PAYG 25Mbps)](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/f5-networks.f5-big-ip-best?tab=PlansAndPrice)
    - Azure CLI: 
        ```bash
        az vm image terms accept --urn f5-networks:f5-big-ip-best:f5-bigip-virtual-edition-25m-best-hourly:16.0.101000
        ```
    - For more marketplace terms information, see Azure [documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage#deploy-an-image-with-marketplace-terms).


## Important Configuration Notes

- By default, this solution creates a username **quickstart** with a **temporary** password set to value of the Azure virtual machine ID **vmId** which is provided in the output of the parent template. **IMPORTANT**: You should change this temporary password immediately following deployment. Alternately, you may remove the quickstart user class from the runtime-init configuration prior to deployment to prevent this user account from being created. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more details.

- This solution requires Internet access for: 
  1. Downloading additional F5 software components used for onboarding and configuring the BIG-IP (via github.com). Internet access is required via the management interface and then via a dataplane interface (ex. external Self-IP) once a default route is configured. See [Overview of Mgmt Routing](https://support.f5.com/csp/article/K13284) for more details. By default, as a convenience, this solution provisions Public IPs to enable this but in a production environment, outbound access should be provided by a `routed` SNAT service (ex. NAT Gateway, custom firewall, etc). *NOTE: access via web proxy is not currently supported. Other options include 1) hosting the file locally and modifying the runtime-init package url and configuration files to point to local URLs instead or 2) baking them into a custom image, using the [F5 Image Generation Tool](https://clouddocs.f5.com/cloud/public/v1/ve-image-gen_index.html).*
  2. Contacting native cloud services for various cloud integrations: 
    - *Onboarding*:
        - [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) - to fetch secrets from native vault services
    - *Operation*:
        - [F5 Application Services 3](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/) - for features like Service Discovery
        - [F5 Telemetry Streaming](https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/) - for logging and reporting
        - [Cloud Failover Extension (CFE)](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/) - for updating ip and routes mappings
    - Additional cloud services like [Private endpoints](https://docs.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#connecting-to-private-endpoints) can be used to address calls to native services traversing the Internet.
  - See [Security](#security) section for more details. 

- This solution template provides an **initial** deployment only for an "infrastructure" use case ( meaning that it does not support managing the entire deployment exclusively via the template's "Redeploy" function).  This solution leverages wa-agent to send the instance **customData**, which is only used to provide an initial BIG-IP configuration and not as the primary configuration API for a long-running platform.  Although "Redeploy" can be used to update some cloud resources, as the BIG-IP configuration needs to align with the cloud resources, like IPs to NICs, updating one without the other can result in inconsistent states, while updating other resources, like the **image** or **instanceType**, can trigger an entire instance re-deloyment. For instance, to upgrade software versions, traditional in-place upgrades should be leveraged. See [AskF5 Knowledge Base](https://support.f5.com/csp/article/K84554955) and [Changing the BIG-IP Deployment](#changing-the-bigip-deployment) for more information.

- If you have cloned this repository in order to modify the templates or BIG-IP config files and published to your own location, you can use the **templateBaseUrl** and **artifactLocation** input parameters to specify the new location of the customized templates and the **bigIpRuntimeInitConfig** input parameter to specify the new location of the BIG-IP Runtime-Init config. See main [/examples/README.md](../README.md#cloud-configuration) for more template customization details. See [Changing the BIG-IP Deployment](#changing-the-bigip-deployment) for more BIG-IP customization details.  

- In this solution, the BIG-IP VE has the [LTM](https://f5.com/products/big-ip/local-traffic-manager-ltm) and [ASM](https://f5.com/products/big-ip/application-security-manager-asm) modules enabled to provide advanced traffic management and web application security functionality. 

- If you are deploying the solution into an Azure region that supports Availability Zones, you can specify True for the useAvailabilityZones parameter. See [Azure Availability Zones](https://docs.microsoft.com/en-us/azure/availability-zones/az-region#azure-regions-with-availability-zones) for a list of regions that support Availability Zones.

- This template can send non-identifiable statistical information to F5 Networks to help us improve our templates. You can disable this functionality by setting the **autoPhonehome** system class property value to false in the F5 Declarative Onboarding declaration. See [Sending statistical information to F5](#sending-statistical-information-to-f5).

- See [trouble shooting steps](#troubleshooting-steps) for more details.

### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| appContainerName | No | The name of a container to download and install which is used for the example application server(s). If this value is left blank, the application module template is not deployed. |
| artifactLocation | No | The directory, relative to the templateBaseUrl, where the modules folder is located. |
| bigIpRuntimeInitConfig | No | Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format, or an escaped JSON string to use for f5-bigip-runtime-init configuration. |
| bigIpRuntimeInitPackageUrl | No | Supply a URL to the bigip-runtime-init package |
| numNics | No | Enter valid number of network interfaces (1-3) to create on the BIG-IP VE instance. |
| restrictedSrcAddressApp | Yes | When creating application security group, this field restricts application access to a specific network or address. Enter an IP address or address range in CIDR notation, or asterisk for all sources. |
| restrictedSrcAddressMgmt | Yes | When creating management security group, this field restricts management access to a specific network or address. Enter an IP address or address range in CIDR notation, or asterisk for all sources. |
| sshKey | Yes | Supply the public key that will be used for SSH authentication to the BIG-IP and application virtual machines. Note: This should be the public key as a string, typically starting with **---- BEGIN SSH2 PUBLIC KEY ----** and ending with **---- END SSH2 PUBLIC KEY ----**. |
| tagValues | No | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique adjust them as needed for each key. |
| templateBaseUrl | No | The publicly accessible URL where the linked ARM templates are located. |
| uniqueString | Yes | A prefix that will be used to name template resources. Because some resources require globally unique names, we recommend using a unique value. |
| useAvailabilityZones | No | This deployment can deploy resources into Azure Availability Zones (if the region supports it).  If that is not desired the input should be set 'No'. If the region does not support availability zones the input should be set to No. |


### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| appPrivateIp | Application Private IP Address | Application Template | string |
| appPublicIps | Application Public IP Addresses | Dag Template | array |
| appUsername | Application user name | Application Template | string |
| appVmName | Application Virtual Machine name | Application Template | string |
| bigipUsername | BIG-IP user name | BIG-IP Template | string |
| mgmtPrivateIp | Management Private IP Address | BIG-IP Template | string |
| mgmtPrivateUrl | Management Private IP Address | BIG-IP Template | string |
| mgmtPublicIp | Management Public IP Address | Dag Template | string |
| mgmtPublicUrl | Management Public IP Address | Dag Template | string |
| vip1PrivateIp | Service (VIP) Private IP Address | Application Template | string |
| vip1PrivateUrlHttp | Service (VIP) Private HTTP URL | Application Template | string |
| vip1PrivateUrlHttps | Service (VIP) Private HTTPS URL | Application Template | string |
| vip1PublicIp | Service (VIP) Public IP Address | Dag Template | string |
| vip1PublicIPDns | Service (VIP) Public DNS | Dag Template | string |
| vip1PublicUrlHttp | Service (VIP) Public HTTP URL | Dag Template | string |
| vip1PublicUrlHttps | Service (VIP) Public HTTPS URL | Dag Template | string |
| virtualNetworkId | Virtual Network resource ID | Network Template | string |
| vmId | Virtual Machine resource ID | BIG-IP Template | string |


## Deploying this Solution

Two options for deploying this solution include:

- Using the [Azure deploy button](#deploying-via-the-azure-deploy-button) - in the Azure Portal
- Using [CLI Tools](#deploying-via-the-azure-cli)

### Deploying via the Azure Deploy button

The easiest way to deploy this Azure Arm templates is to use the deploy button below:<br>

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FF5Networks%2Ff5-azure-arm-templates-v2%2Fv1.2.0.0%2Fexamples%2Fquickstart%2Fazuredeploy.json)

*Step 1: Custom Template Page* 
  - Select or Create New Resource Group
  - Fill in the *REQUIRED* parameters (with * next to them). 
    - **sshKey**
    - **restrictedSrcAddressApp**
    - **restrictedSrcAddressMgmt**
    - **uniqueString**
  - Click "Next: Review + Create"

*Step 2: Custom Template Page*
  - After "Validation Passed"
    - Click "Create"

For next steps, see [Validating the Deployment](#validating-the-deployment).

### Deploying via the Azure CLI

As an alternative to deploying through the Azure Portal (GUI), each solution provides an example Azure CLI 2.0 command to deploy the ARM template. The following example deploys a 3-NIC BIG-IP VE.

#### Azure CLI (2.0) Script Example

*NOTE: First replace parameter values with `<YOUR_VALUE>` with your values.*

```bash
RESOURCE_GROUP="myGroupName"
REGION="eastus"
DEPLOYMENT_NAME="myDeployment"
TEMPLATE_URI="https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v1.2.0.0/examples/quickstart/azuredeploy.json"
DEPLOY_PARAMS='{"templateBaseUrl":{"value":"https://cdn.f5.com/product/cloudsolutions/"},"artifactLocation":{"value":"f5-azure-arm-templates-v2/v1.2.0/examples/"},"uniqueString":{"value":"<value>"},"sshKey":{"value":"<YOUR_VALUE>"},"instanceType":{"value":"Standard_DS4_v2"},"image":{"value":"f5-networks:f5-big-ip-byol:f5-big-all-2slot-byol:15.1.200000"},"appContainerName":{"value":"f5devcentral/f5-demo-app:latest"},"restrictedSrcAddressMgmt":{"value":"<YOUR_VALUE>"},"restrictedSrcAddressApp":{"value":"<YOUR_VALUE>"}, "bigIpRuntimeInitConfig":{"value":"https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v0.0.2/examples/quickstart/bigip-configurations/runtime-init-conf-3nic-byol.yaml"},"useAvailabilityZones":{"value":False},"numNics":{"value":3}}'
DEPLOY_PARAMS_FILE=${TMP_DIR}/deploy_params.json
echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}

az group create -n ${RESOURCE_GROUP} -l ${REGION}
az deployment group create --resource-group ${RESOURCE_GROUP} -l ${REGION} --name ${DEPLOYMENT_NAME} --template-uri ${TEMPLATE_URI}  --parameters @${DEPLOY_PARAMS_FILE}
```

For next steps, see [Validating the Deployment](#validating-the-deployment).


### Changing the BIG-IP Deployment

You will most likely want or need to change the BIG-IP configuration. This generally involves referencing or customizing a [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) configuration file and passing it through the **bigIpRuntimeInitConfig** template parameter as a URL or inline json. 

ex. from azuredeploy.parameters.json
```json
    "useAvailabilityZones": {
        "value": false
    },
    "bigIpRuntimeInitConfig": {
        "value": "https://raw.githubusercontent.com/f5networks/f5-azure-arm-templates-v2/v1.2.0.0/examples/quickstart/bigip-configurations/runtime-init-conf-3nic-payg.yaml"
    },
```

The F5 BIG-IP Runtime Init configuration file can also be formatted in json and/or passed directly inline:

```json
    "useAvailabilityZones": {
        "value": false
    },
    "bigIpRuntimeInitConfig": {
        "value": "{\"pre_onboard_enabled\":[{\"name\":\"provision_rest\",\"type\":\"inline\",\"commands\":[\"/usr/bin/setdbprovision.extramb1000\",\"/usr/bin/setdbrestjavad.useextrambtrue\"]}],\"runtime_parameters\":[{\"name\":\"HOST_NAME\",\"type\":\"metadata\",\"metadataProvider\":{\"type\":\"compute\",\"environment\":\"azure\",\"field\":\"name\"}},{\"name\":\"BIGIP_PASSWORD\",\"type\":\"url\",\"query\":\"vmId\",\"value\":\"http://169.254.169.254/metadata/instance/compute?api-version=2017-08-01\",\"headers\":[{\"name\":\"Metadata\",\"value\":true}]},{\"name\":\"SELF_IP_EXTERNAL\",\"type\":\"metadata\",\"metadataProvider\":{\"type\":\"network\",\"environment\":\"azure\",\"field\":\"ipv4\",\"index\":1}},{\"name\":\"SELF_IP_INTERNAL\",\"type\":\"metadata\",\"metadataProvider\":{\"type\":\"network\",\"environment\":\"azure\",\"field\":\"ipv4\",\"index\":2}}],\"bigip_ready_enabled\":[],\"extension_packages\":{\"install_operations\":[{\"extensionType\":\"do\",\"extensionVersion\":\"1.19.0\",\"extensionHash\":\"15c1b919954a91b9ad1e469f49b7a0915b20de494b7a032da9eb258bbb7b6c49\"},{\"extensionType\":\"as3\",\"extensionVersion\":\"3.26.0\",\"extensionHash\":\"b33a96c84b77cff60249b7a53b6de29cc1e932d7d94de80cc77fb69e0b9a45a0\"},{\"extensionType\":\"ts\",\"extensionVersion\":\"1.18.0\",\"extensionHash\":\"de4c82cafe503e65b751fcacfb2f169912ad5ce1645e13c5135dca972299174a\"},{\"extensionType\":\"fast\",\"extensionVersion\":\"1.7.0\",\"extensionHash\":\"9c617f5bb1bb0d08ec095ce568a6d5d2ef162e504cd183fe3540586200f9d950\"}]},\"extension_services\":{\"service_operations\":[{\"extensionType\":\"do\",\"type\":\"inline\",\"value\":{\"schemaVersion\":\"1.0.0\",\"class\":\"Device\",\"async\":true,\"label\":\"Quickstart 3NIC BIG-IP declaration for Declarative Onboarding with BYOL license\",\"Common\":{\"class\":\"Tenant\",\"dbVars\":{\"class\":\"DbVariables\",\"provision.extramb\":1000,\"restjavad.useextramb\":true,\"ui.advisory.enabled\":true,\"ui.advisory.color\":\"blue\",\"ui.advisory.text\":\"BIG-IPVEQuickstart\",\"config.allow.rfc3927\":\"enable\",\"dhclient.mgmt\":\"disable\"},\"myDns\":{\"class\":\"DNS\",\"nameServers\":[\"168.63.129.16\"]},\"myLicense\":{\"class\":\"License\",\"licenseType\":\"regKey\",\"regKey\":\"AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE\"},\"myNtp\":{\"class\":\"NTP\",\"servers\":[\"0.pool.ntp.org\"],\"timezone\":\"UTC\"},\"myProvisioning\":{\"class\":\"Provision\",\"ltm\":\"nominal\",\"asm\":\"nominal\"},\"mySystem\":{\"class\":\"System\",\"autoPhonehome\":true,\"hostname\":\"{{{HOST_NAME}}}.local\"},\"quickstart\":{\"class\":\"User\",\"userType\":\"regular\",\"partitionAccess\":{\"all-partitions\":{\"role\":\"admin\"}},\"password\":\"{{{BIGIP_PASSWORD}}}\",\"shell\":\"bash\"},\"default\":{\"class\":\"ManagementRoute\",\"gw\":\"10.0.0.1\",\"network\":\"default\"},\"dhclient_route1\":{\"class\":\"ManagementRoute\",\"gw\":\"10.0.0.1\",\"network\":\"168.63.129.16/32\"},\"azureMetadata\":{\"class\":\"ManagementRoute\",\"gw\":\"10.0.0.1\",\"network\":\"169.254.169.254/32\"},\"defaultRoute\":{\"class\":\"Route\",\"gw\":\"10.0.1.1\",\"network\":\"default\"},\"external\":{\"class\":\"VLAN\",\"tag\":4094,\"mtu\":1500,\"interfaces\":[{\"name\":\"1.1\",\"tagged\":false}]},\"external-self\":{\"class\":\"SelfIp\",\"address\":\"{{{SELF_IP_EXTERNAL}}}\",\"vlan\":\"external\",\"allowService\":\"none\",\"trafficGroup\":\"traffic-group-local-only\"},\"internal\":{\"class\":\"VLAN\",\"tag\":4093,\"mtu\":1500,\"interfaces\":[{\"name\":\"1.2\",\"tagged\":false}]},\"internal-self\":{\"class\":\"SelfIp\",\"address\":\"{{{SELF_IP_INTERNAL}}}\",\"vlan\":\"internal\",\"allowService\":\"default\",\"trafficGroup\":\"traffic-group-local-only\"}}}},{\"extensionType\":\"as3\",\"type\":\"inline\",\"value\":{\"class\":\"ADC\",\"schemaVersion\":\"3.0.0\",\"label\":\"Quickstart\",\"remark\":\"Quickstart\",\"Tenant_1\":{\"class\":\"Tenant\",\"Shared\":{\"class\":\"Application\",\"template\":\"shared\",\"shared_pool\":{\"class\":\"Pool\",\"remark\":\"Service 1 shared pool\",\"members\":[{\"serverAddresses\":[\"10.0.3.4\"],\"servicePort\":80}],\"monitors\":[\"http\"]}},\"HTTP_Service\":{\"class\":\"Application\",\"template\":\"http\",\"serviceMain\":{\"class\":\"Service_HTTP\",\"virtualAddresses\":[\"10.0.1.101\"],\"snat\":\"auto\",\"policyWAF\":{\"use\":\"WAFPolicy\"},\"pool\":\"/Tenant_1/Shared/shared_pool\"},\"WAFPolicy\":{\"class\":\"WAF_Policy\",\"url\":\"https://raw.githubusercontent.com/f5devcentral/f5-asm-policy-templates/master/generic_ready_template/Rapid_Depolyment_Policy_13_1.xml\",\"enforcementMode\":\"blocking\",\"ignoreChanges\":false}},\"HTTPS_Service\":{\"class\":\"Application\",\"template\":\"https\",\"serviceMain\":{\"class\":\"Service_HTTPS\",\"virtualAddresses\":[\"10.0.1.101\"],\"snat\":\"auto\",\"policyWAF\":{\"use\":\"WAFPolicy\"},\"pool\":\"/Tenant_1/Shared/shared_pool\",\"serverTLS\":{\"bigip\":\"/Common/clientssl\"},\"redirect80\":false},\"WAFPolicy\":{\"class\":\"WAF_Policy\",\"url\":\"https://raw.githubusercontent.com/f5devcentral/f5-asm-policy-templates/master/generic_ready_template/Rapid_Depolyment_Policy_13_1.xml\",\"enforcementMode\":\"blocking\",\"ignoreChanges\":false}}}}}]},\"post_onboard_enabled\":[]}"
    },
```

NOTE: If providing the json inline as a template parameter, you must escape all double quotes so it can be passed as a single parameter string.

*TIP: If you haven't forked/published your own repository or don't have an easy way to host your own config files, passing the config as inline json via the template input parameter might be the quickest / most accessible option to test out different BIG-IP configs using this repository.*

F5 has provided the following example configuration files in the `examples/quickstart/bigip-configurations` folder:

- These examples install Automation Tool Chain packages and create WAF-protected services for a PAYG licensed deployment.
  - `runtime-init-conf-1nic-payg.yaml`
  - `runtime-init-conf-2nic-payg.yaml`
  - `runtime-init-conf-3nic-payg.yaml`
- These examples install Automation Tool Chain packages and create WAF-protected services for a BYOL licensed deployment.
  - `runtime-init-conf-1nic-byol.yaml`
  - `runtime-init-conf-2nic-byol.yaml`
  - `runtime-init-conf-3nic-byol.yaml`
- `Rapid_Deployment_Policy_13_1.xml` - This ASM security policy is supported for BIG-IP 13.1 and later.

See [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) for more examples.  

By default, this solution deploys a 3NIC BIG-IP using the example `runtime-init-conf-3nic-payg.yaml`.

In order to deploy a **1NIC** instance:
  1. Update the **bigIpRuntimeInitConfig** input parameter to reference a corresponding `1nic` config file (ex. runtime-init-conf-1nic-payg.yaml )
  2. Update the **numNics** input parameter to **1**

In order to deploy a **2NIC** instance:
  1. Update the **bigIpRuntimeInitConfig** input parameter to reference a corresponding `2nic` config file (ex. runtime-init-conf-2nic-payg.yaml )
  2. Update the **numNics** input parameter to **2**

- When specifying values for the instanceType and numNics parameters, ensure that the instance type you select is appropriate for the deployment scenario. See [Azure Virtual Machine Instance Types](https://docs.microsoft.com/en-us/azure/virtual-machines/dv2-dsv2-series) for more information.

However, most changes require modifying the configurations themselves. For example:

In order to deploy a **BYOL** instance:

  1. edit/modify the Declarative Onboarding (DO) declaration in a corresponding `byol` runtime-init config file with the new `regKey` value. 

ex.
```yaml
          myLicense:
            class: License
            licenseType: regKey
            regKey: AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE
```
  2. publish/host the customized runtime-init config file at a location reachable by the BIG-IP at deploy time (ex. github, Azure Storage, etc)
  3. Update the **bigIpRuntimeInitConfig** input parameter to reference the new URL of the updated configuration 
  4. Update the **image** input parameter to use `byol` image.
        ex.
        ```json 
        "image":{ 
          "value": "f5-networks:f5-big-ip-byol:f5-big-all-2slot-byol:16.0.101000" 
        }
        ```

In order deploy additional **virtual services**:

For illustration purposes, this solution pre-provisions IP addresses and the runtime-init configurations contain an AS3 declaration to create an example virtual service. However, in practice, cloud-init runs once and is typically used for initial provisioning, not as the primary configuration API for a long-running platform. More typically in an infrastructure use case, virtual services are not included in the initial cloud-init configuration are added post initial deployment which involves:
  1. *Cloud*  - Provisioning additional IPs on the desired Network Interfaces. ex.
      - [az network nic ip-config create](https://docs.microsoft.com/en-us/cli/azure/network/nic/ip-config?view=azure-cli-latest#az_network_nic_ip_config_create)
      - [az network public-ip create](https://docs.microsoft.com/en-us/cli/azure/network/public-ip?view=azure-cli-latest#az_network_public_ip_create)
      - [az network nic ip-config update](https://docs.microsoft.com/en-us/cli/azure/network/nic/ip-config?view=azure-cli-latest#az_network_nic_ip_config_update)
  2. *BIG-IP* - Creating Virtual Services that match those additional Secondary IPs 
      - ex. updating the [AS3](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/composing-a-declaration.html) declaration with additional Virtual Services (see **virtualAddresses:**).


*NOTE: For cloud resources, templates can be customized to pre-provision and update addtional resources (ex. various combinations of NICs, Private IPs, Public IPs, etc). Please see [Getting Help](#getting-help) for more information. For BIG-IP configurations, you can leverage any REST or Automation Tool Chain clients like [Ansible](https://ansible.github.io/workshops/exercises/ansible_f5/3.0-as3-intro/),[Terraform](https://registry.terraform.io/providers/F5Networks/bigip/latest/docs/resources/bigip_as3),etc.*


## Validation

This section describes how to validate the template deployment, test the WAF service, and troubleshoot common problems.

### Validating the Deployment

To view the status of the example and module template deployments, navigate to Resource Groups->**RESOURCE_GROUP**->Deployments. You should see a series of deployments, including the parent template as well as the linked templates, which can include: networkTemplate, appTemplate, dagTemplate and bigipTemplate. The deployment status for each template deployment should be "Succeeded".  

Expected Deploy time for entire stack =~ 13-15 minutes.

If any of the deployments are in a failed state, proceed to the [Troubleshooting Steps](#troubleshooting-steps) section below.

### Accessing the BIG-IP

SSH:
- Obtain the IP address of the BIG-IP Mangement Port:
  - **Console**: Navigate to Resource Groups->**RESOURCE_GROUP**->Deployments->**DEPLOYMENT_NAME**->Outputs->mgmtPublicIp
  - **Azure CLI**: 
    ``` bash 
    az group deployment show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} -o json --query properties.outputs.mgmtPublicIp.value
    ```
- Login in via SSH:
  - **SSH key authentication**: 
    ```bash
    ssh quickstart@${IP_ADDRESS_FROM_OUTPUT} -i ${PATH_TO_YOUR_PRIVATE_sshKey}
    ```

WebUI: 
- Obtain the URL address of the BIG-IP Mangement Port:
  - **Console**: Navigate to Resource Groups->**RESOURCE_GROUP**->Deployments->**DEPLOYMENT_NAME**->Outputs->mgmtPublicUrl
  - **Azure CLI**: ```az group deployment show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME}  -o json --query properties.outputs.mgmtPublicUrl.value```

- Open a browser to the Management IP:
  - NOTE: By default the BIG-IP's WebUI starts with a self-signed cert. Follow your browsers instructions for accepting self-signed certs (ex. If using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click "Advanced" button, Click "Accept Risk and Continue").
  - Provide 
    - username: quickstart
    - password: **vmID** (obtain from arm deployment template "Outputs")


### Further Exploring

#### WebUI
 - Navigate to Virtual Services 
    - From Drop Down Box named "Partition" *(Upper Right)*
      - Select Partition = `Tenant_1`
    - Navigate to Local Traffic *(Tabs on Left)*
        - Select `Virtual Servers`
          - You should see two Virtual Services (one for HTTP and one for HTTPS). The should show up as Green. Click on them to look at the configuration *(declared in the AS3 declaration)*

#### SSH

  - From tmsh shell, type 'bash' to enter the bash shell
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


### Testing the WAF Service

To test the WAF service, perform the following steps:
- Obtain the IP address of the WAF service:
  - **Console**: Navigate to Resource Groups->**RESOURCE_GROUP**->Deployments->**DEPLOYMENT_NAME**->Outputs->vip1PublicIp
  - **Azure CLI**: 
      ```bash
      az group deployment show --resource-group ${RESOURCE_GROUP} --name ${DEPLOYMENT_NAME} -o json --query properties.outputs.vip1PublicIp.value[0]
      ```
- Verify the application is responding:
  - Paste the IP address in a browser: ```https://${IP_ADDRESS_FROM_OUTPUT}```
      - NOTE: By default the Virtual Service starts with a self-signed cert. Follow your browsers instructions for accepting self-signed certs (ex. If using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click "Advanced" button, Click "Accept Risk and Continue", etc. ).
  - Use curl: 
      ```shell
       curl -sko /dev/null -w '%{response_code}\n' https://${IP_ADDRESS_FROM_OUTPUT}
       ```
- Verify the WAF is configured to block illegal requests:
    ```shell
    curl -sk -X DELETE https://${IP_ADDRESS_FROM_OUTPUT}
    ```
  - The response should include a message that the request was blocked, and a reference support ID
    ex.
    ```shell
    $ curl -sko /dev/null -w '%{response_code}\n' https://55.55.55.55
    200
    $ curl -sk -X DELETE https://55.55.55.55
    <html><head><title>Request Rejected</title></head><body>The requested URL was rejected. Please consult with your administrator.<br><br>Your support ID is: 2394594827598561347<br><br><a href='javascript:history.back();'>[Go Back]</a></body></html>
    ```


## Deleting this Solution

### Deleting the deployment via Azure Portal 

Home -> Select "Resource Groups" Icon  
  - Select your Resource Group (click on link) 
    - Click "Delete Resource Group" 
     - Type the Name of the Resource Group when prompted to confirm
      - Click "Delete"

### Deleting the deployment using the Azure CLI

```bash
az group delete -n ${RESOURCE_GROUP}
```


## Troubleshooting Steps

There are generally two classes of issues:

1. Template deployment itself failed
2. Resource(s) within the template failed to deploy

To verify that all templates deployed successfully, follow the instructions under **Validating the Deployment** above to locate the failed deployment(s).

Click on the name of a failed deployment and then click Events. Click the link in the red banner at the top of the deployment overview for details about the failure cause. 

Additionally, if the template passed validation but individual template resources have failed to deploy, you can see more information by expanding Deployment Details, then clicking on the Operation details column for the failed resource. **When creating a Github issue for a template, please include as much information as possible from the failed Azure deployment/resource events.**

Common deployment failure causes include:
- Required fields were left empty or contained incorrect values (input type mismatch, prohibited characters, malformed JSON, etc.) causing template validation failure
- Insufficient permissions to create the deployment or resources created by a deployment
- Resource limitations (exceeded limit of IP addresses or compute resources, etc.)
- Azure service issues (these will usually surface as 503 internal server errors in the deployment status error message)

If all deployments completed "successfully" but maybe the BIG-IP or Service is not reachable, then log in to the BIG-IP instance via SSH to confirm BIG-IP deployment was successful (for example, if startup scripts completed as expected on the BIG-IP). To verify BIG-IP deployment, perform the following steps:
- Obtain the IP address of the BIG-IP instance. See instructions [above](#accessing-the-bigip-ip)
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
- *GENERAL LOG TIP*: Search most critical error level errors first (ex. egrep -i err /var/log/<Logname>).

If you are unable to login to the BIG-IP instance(s), you can navigate to Resource Groups->**RESOURCE_GROUP**->Overview->**instance name**->Support and Troubleshooting->Serial console for additional information from Azure.


## Security

This ARM template downloads helper code to configure the BIG-IP system:

- f5-bigip-runtime-init.gz.run: The self-extracting installer for the F5 BIG-IP Runtime Init RPM can be verified against a SHA256 checksum provided as a release asset on the F5 BIG-IP Runtime Init public Github repository, for example: https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.0.0/f5-bigip-runtime-init-1.0.0-1.gz.run.sha256.
- F5 BIG-IP Runtime Init: The self-extracting installer script extracts, verifies, and installs the F5 BIG-IP Runtime Init RPM package. Package files are signed by F5 and automatically verified using GPG.
- F5 Automation Toolchain components: F5 BIG-IP Runtime Init downloads, installs, and configures the F5 Automation Toolchain components. Although it is optional, F5 recommends adding the extensionHash field to each extension install operation in the configuration file. The presence of this field triggers verification of the downloaded component package checksum against the provided value. The checksum values are published as release assets on each extension's public Github repository, for example: https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.18.0/f5-appsvcs-3.18.0-4.noarch.rpm.sha256

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

More information about F5 BIG-IP Runtime Init and additional examples can be found in the [Github repository](https://github.com/F5Networks/f5-bigip-runtime-init/blob/main/README.md).

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
| 16.0.101000 | 16.0.1.1 Build 0.0.6 |
| 14.1.400000 | 14.1.4 Build 0.0.11 |


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
