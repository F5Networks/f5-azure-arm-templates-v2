
# Deploying BIG-IP Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-azure-arm-templates-v2.svg)](https://github.com/f5networks/f5-azure-arm-templates-v2/issues)

## Contents

- [Deploying BIG-IP Template](#deploying-big-ip-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Example Configurations](#example-configurations)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)

## Introduction

This ARM template creates a BIG-IP Virtual Machine (VM) and optionally associates specified role definition with system assigned managed identity. Link this template to create BIG-IP VM required for F5 deployments. You can link the template multiple times for high availability.

## Prerequisites

 - F5-bigip-runtime-init configuration file required. See https://github.com/F5Networks/f5-bigip-runtime-init for more details on F5-bigip-runtime-init SDK. See runtime-init-conf.yaml examples in the repository.
 - Declarative Onboaring (DO) declaration: See quickstart_do_*.json examples in the repository.
 - AS3 declaration: See quickstart_a3.json example in the repository.
 - Telemetry Streaming (TS) declaration if using custom metrics. See quickstart_ts.json example in the repository.
 
## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add bigip.json as a linked template into your templated solution.
- Troubleshooting: The log location for f5-bigip-runtime-init onboarding is ``/var/log/cloud/bigIpRuntimeInit.log``. By default, the log level is set to info; however, you can set a custom log level by exporting the F5_BIGIP_RUNTIME_INIT_LOG_LEVEL environment variable before invoking f5-bigip-runtime-init in commandToExecute: 
```export F5_BIGIP_RUNTIME_INIT_LOG_LEVEL=silly && bash ', variables('runtimeConfigPackage'), ' azure 2>&1```



### Template Input Parameters

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details.

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| adminUsername | No | "azureuser" | string | Enter a valid BIG-IP username. This creates the specified username on the BIG-IP with admin role. |
| allowUsageAnalytics | No | true | boolean | This deployment can send anonymous statistics to F5 to help us determine how to improve our solutions. If you select **false** statistics are not sent. |
| bigIpPeerAddr | No |  | string | Provide the static address of the remote peer used for clustering. In this failover solution, clustering is initiated from the second instance (02) to the first instance (01) so you would provide the first instances Self IP address. |
| bigIpPeerHostname | No |  | string | Type the hostname of the remote host here. Leave empty if not configuring peering with a remote host on this device. |
| bigIpRuntimeInitConfig | Yes |  | string | URL to bigip-runtime-init configuration file or json string to use for configuration file. |
| bigIpRuntimeInitPackageUrl | No | https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.4.1/dist/f5-bigip-runtime-init-1.4.1-1.gz.run | string | Supply a URL to the bigip-runtime-init package. |
| cfeStorageAccountName | No |  | string | CFE storage account created and used for cloud-failover-extension. |
| cfeTag | No |  | string | Cloud Failover deployment tag value. |
| hostname | No | bigip01.local | string | Supply the hostname you would like to use for the BIG-IP instance. The hostname must contain fewer than 63 characters. |
| image | No | "f5-networks:f5-big-ip-best:f5-bigip-virtual-edition-25m-best-hourly:15.1.201000" | string | There are two acceptable formats: Enter the URN of the image to use in Azure marketplace, or enter the ID of the custom image. An example URN value: 'f5-networks:f5-big-ip-byol:f5-big-ltm-2slot-byol:15.1.002000'. You can find the URNs of F5 marketplace images in the README for this template or by running the command: ``az vm image list --output yaml --publisher f5-networks --all``. See [this documentation](https://clouddocs.f5.com/cloud/public/v1/azure/Azure_download.html) for information on creating a custom BIG-IP image. |
| instanceType | No | "Standard_D8s_v4" | string | Enter a valid instance type. |
| licenseKey | No |  | string | Supply the F5 BYOL license key for the BIG-IP instance. Leave this parameter blank if deploying the PAYG solution. |
| mgmtNsgId | No |  | string | The resource ID of a network security group to apply to the management network interface. |
| mgmtPublicIpId | No |  | string | The resource ID of the public IP address to apply to the management network interface. Leave this parameter blank to create a management network interface without a public IP address. |
| mgmtSelfIp | No |  | string | The private IP address to apply to the primary IP configuration on the management network interface. The address must reside in the subnet provided in the mgmtSubnetId parameter. |
| mgmtSubnetId | Yes |  | string | The resource ID of the management subnet. |
| nic1NsgId | No |  | string | The optional resource ID of a network security group to apply to the first non-management network interface.|
| nic1PrimaryPublicId | No |  | string | The resource ID of the public IP address to apply to the primary IP configuration on the first non-management network interface. |
| nic1SelfIp | No |  | string | The private IP address to apply to the primary IP configuration on the first non-management network interface. The address must reside in the subnet provided in the nic1SubnetId parameter. |
| nic1ServiceIPs | No |  | array | An array of one or more public/private IP address pairs to apply to the secondary external IP configurations on the first non-management network interface. The private addresses must reside in the subnet provided in the same subnet as the network interface, if deploying with 2 or more network interfaces. When deploying a 1 NIC BIG-IP VE, these IP configurations will be created on the management network interface, and the addresses must reside in the subnet provided in the mgmtSubnetId parameter. For example, this value will create one public/private and one private IP configuration on NIC1: ```[{"publicIpId":"/subscriptions/<subscriptionId>/resourceGroups/<resource group name>/providers/Microsoft.Network/publicIPAddresses/<public ip name>","privateIpAddress":"10.0.1.10"},{"privateIpAddress":"10.0.1.11"}]``` |
| nic1SubnetId | No |  | string | The resource ID of the subnet to apply to the first non-management network interface. |
| nic2NsgId | No |  | string | The optional resource ID of a network security group to apply to the second non-management network interface. |
| nic2PrimaryPublicId | No |  | string | The resource ID of the public IP address to apply to the primary IP configuration on the second non-management network interface. |
| nic2SelfIp | No |  | string | The private IP address to apply to the primary IP configuration on the second non-management network interface. The address must reside in the subnet provided in the nic2SubnetId parameter. |
| nic2ServiceIPs | No |  | array | An array of one or more public/private IP address pairs to apply to the secondary external IP configurations on the first non-management network interface. The private addresses must reside in the subnet provided in the same subnet as the network interface, if deploying with 2 or more network interfaces. When deploying a 1 NIC BIG-IP VE, these IP configurations will be created on the management network interface, and the addresses must reside in the subnet provided in the mgmtSubnetId parameter. For example, this value will create one public/private and one private IP configuration on NIC2: ```[{"publicIpId":"/subscriptions/<subscriptionId>/resourceGroups/<resource group name>/providers/Microsoft.Network/publicIPAddresses/<public ip name>","privateIpAddress":"10.0.2.10"},{"privateIpAddress":"10.0.2.11"}]```|
| nic2SubnetId | No |  | string | The resource ID of the internal subnet to apply to the second non-management network interface. |
| roleDefinitionId | No |  | string | Enter a role definition ID you want to add to system managed identity. Leave default if system managed identity is not used. |
| secretId | No |  | string | The full URL of the secretId where the BIG-IP password is stored, including KeyVault Name. For example: https://yourvaultname.vault.azure.net/secrets/yoursecretid. |
| sshKey | Yes |  | string | Supply the SSH public key you want to use to connect to the BIG-IP. |
| tagValues | No | "application": "f5demoapp", "cost": "f5cost", "environment": "f5env", "group": "f5group", "owner": "f5owner" | object | Default key/value resource tags will be added to the resources in this deployment, if you would like the values to be unique, adjust them as needed for each key. |
| uniqueString | Yes |  | string | Unique DNS Name for the Public IP address used to access the Virtual Machine and postfix resource names. |
| userAssignManagedIdentity | No |  | string | Enter user-assigned management identity Id to be associated to VM. Leave default if not used. |
| vmName | No | "bigip-vm" | string | Name to use for Virtual Machine. |
| workspaceId | No | "WORKSPACE_ID" | string | Log Analytics workspace ID used by Telemetry Streaming for sending logs. |
| zone | No | "" | string | If using Availability Zones, provide the zone number for this BIG-IP instance. |

### Template Outputs

| Name | Required Resource | Type | Description |
| --- | --- | --- | --- |
| roleAssignmentId | Role Definition | string | Role Assignment resource ID |
| selfIp0 | Network Interface | string | Private IP addresses |
| selfIp1 | Network Interface | string | Private IP addresses |
| selfIp2 | Network Interface | string | Private IP addresses |
| selfIp3 | Network Interface | string | Private IP addresses |
| vmId | Virtual Machine | string | Virtual Machine resource ID |


## Example Configurations

**f5-bigip-runtime-init json example**
- See \<Add URL to f5-bigip-runtime-init readme.md\> for additional examples.
- Note: All quotes are escaped as parameter type expected is string.
- Note: Self IP address order in the runtime_parameters network metadata provider index is determined by the network interface assignment order in the ARM template; for example, the primary IP address on the first non-management network interface assigned to the virtual machine will always be accessed using an index of 1, the second using an index of 2, etc. 
Example on one line:  
```json
{\"runtime_parameters\":[{\"name\":\"HOST_NAME\",\"type\":\"tag\",\"tagProvider\":{\"environment\":\"azure\",\"key\":\"hostname\"}},{\"name\":\"SELF_IP_INTERNAL\",\"type\":\"metadata\",\"metadataProvider\":{\"environment\":\"azure\",\"type\":\"network\",\"field\":\"ipv4\",\"index\":1}},{\"name\":\"SELF_IP_EXTERNAL\",\"type\":\"metadata\",\"metadataProvider\":{\"environment\":\"azure\",\"type\":\"network\",\"field\":\"ipv4\",\"index\":2}}],\"pre_onboard_enabled\":[],\"post_onboard_enabled\":[{\"name\":\"sleep300\",\"type\":\"inline\",\"commands\":[\"sleep300\"]}],\"extension_packages\":{\"install_operations\":[{\"extensionType\":\"do\",\"extensionVersion\":\"1.16.0\",\"extensionHash\":\"536eccb9dbf40aeabd31e64da8c5354b57d893286ddc6c075ecc9273fcca10a1\"},{\"extensionType\":\"as3\",\"extensionVersion\":\"3.23.0\",\"extensionHash\":\"de615341b91beaed59195dceefc122932580d517600afce1ba8d3770dfe42d28\"},{\"extensionType\":\"ts\",\"extensionVersion\":\"1.15.0\",\"extensionHash\":\"333e11a30ba88699ac14bc1e9546622540a5e889c415d5d53a8aeaf98f6f872e\"}]},\"extension_services\":{\"service_operations\":[{\"extensionType\":\"do\",\"type\":\"url\",\"value\":\"https://cdn.f5.com/product/cloudsolutions/declarations/template2-0/quickstart-waf/quickstart.json\"},{\"extensionType\":\"as3\",\"type\":\"url\",\"value\":\"https://cdn.f5.com/product/cloudsolutions/declarations/template2-0/quickstart-waf/quickstart.json\"},{\"extensionType\":\"ts\",\"type\":\"url\",\"value\":\"https://cdn.f5.com/product/cloudsolutions/declarations/template2-0/quickstart-waf/quickstart.json\"}]}}
```
- Same example expanded:

```json
{
  \"extension_packages\": {
    \"install_operations\": [
      {
        \"extensionHash\": \"536eccb9dbf40aeabd31e64da8c5354b57d893286ddc6c075ecc9273fcca10a1\",
        \"extensionType\": \"do\",
        \"extensionVersion\": \"1.16.0\"
      },
      {
        \"extensionHash\": \"de615341b91beaed59195dceefc122932580d517600afce1ba8d3770dfe42d28\",
        \"extensionType\": \"as3\",
        \"extensionVersion\": \"3.23.0\"
      },
      {
        \"extensionHash\": \"333e11a30ba88699ac14bc1e9546622540a5e889c415d5d53a8aeaf98f6f872e\",
        \"extensionType\": \"ts\",
        \"extensionVersion\": \"1.15.0\"
      }
    ]
  },
  \"extension_services\": {
    \"service_operations\": [
      {
        \"extensionType\": \"do\",
        \"type\": \"url\",
        \"value\": \"https://cdn.f5.com/product/cloudsolutions/declarations/template2-0/quickstart-waf/quickstart.json\"
      },
      {
        \"extensionType\": \"as3\",
        \"type\": \"url\",
        \"value\": \"https://cdn.f5.com/product/cloudsolutions/declarations/template2-0/quickstart-waf/quickstart.json\"
      },
      {
        \"extensionType\": \"ts\",
        \"type\": \"url\",
        \"value\": \"https://cdn.f5.com/product/cloudsolutions/declarations/template2-0/quickstart-waf/quickstart.json\"
      }
    ]
  },
  \"post_onboard_enabled\": [
    {
      \"commands\": [
        \"sleep 300\"
      ],
      \"name\": \"sleep 300\",
      \"type\": \"inline\"
    }
  ],
  \"pre_onboard_enabled\": [],
  \"runtime_parameters\": [
    {
         \"name\": \"HOST_NAME\",
         \"type\": \"tag\",
         \"tagProvider\": {
            \"environment\": \"azure\",
            \"key\": \"hostname\"
         }
      },
      {
         \"name\": \"SELF_IP_INTERNAL\",
         \"type\": \"metadata\",
         \"metadataProvider\": {
            \"environment\": \"azure\",
            \"type\": \"network\",
            \"field\": \"ipv4\",
            \"index\": 1
         }
      },
      {
         \"name\": \"SELF_IP_EXTERNAL\",
         \"type\": \"metadata\",
         \"metadataProvider\": {
            \"environment\": \"azure\",
            \"type\": \"network\",
            \"field\": \"ipv4\",
            \"index\": 2
         }
      }
  ]
}
```

**provisionPublicIPs json example**
- One line example:
```json
[{ "name": "publicIp01", "properties": { "idleTimeoutInMinutes": 15 } }]
```
- Same example expanded:
```json
[
    {
        "name": "publicIp01",
        "properties": {
            "idleTimeoutInMinutes": 15
        }
    }
]
```

**Declarative Onboarding Declaration Example**
- See https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/ for more information.
- Onboarding declaration that supports BYOL onboarding.
- Note:
  - HOST_NAME has been defined in the example runtimeConfig. This is required to set the BIG-IP instance host name based on the value of the **bigIpHostName** input parameter. This parameter is not required when setting host name statically.
  - SELF_IP_EXTERNAL has been defined in the example runtimeConfig. This is required to dynamically set the BIG-IP external self IP address based on private IP address set by Azure DHCP. This parameter is not required when setting the external self IP address statically.
  - SELF_IP_INTERNAL has been defined in the example runtimeConfig. This is required to dynamically set the BIG-IP internal self IP address based on private IP address set by Azure DHCP. This parameter is not required when setting the internal self IP address statically.

```json
{
	"schemaVersion": "1.0.0",
	"class": "Device",
	"async": true,
	"label": "Standalone 3NIC BIG-IP declaration for Declarative Onboarding with BYOL license",
	"Common": {
		"class": "Tenant",
		"My_Ntp": {
			"class": "NTP",
			"servers": [
				"0.pool.ntp.org"
			],
			"timezone": "UTC"
		},
		"My_System": {
			"autoPhonehome": true,
			"class": "System",
			"hostname": "{{{ HOST_NAME }}}"
		},
		"My_License": {
            "class": "License",
            "licenseType": "regKey",
            "regKey": "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE"
        },
		"My_Provisioning": {
            "class": "Provision",
            "ltm": "nominal",
            "asm": "nominal"
        },
		"admin": {
            "class": "User",
            "userType": "regular",
            "password": "{{{ BIGIP_PASSWORD }}}",
            "shell": "bash"
        },
		"external": {
			"class": "VLAN",
			"tag": 4094,
			"mtu": 1500,
			"interfaces": [
                {
                    "name": "1.1",
                    "tagged": true
			    }
            ]
		},
		"external-self": {
			"class": "SelfIp",
			"address": "{{{ SELF_IP_EXTERNAL }}}",
			"vlan": "external",
			"allowService": "none",
			"trafficGroup": "traffic-group-local-only"
		},
		"internal": {
			"class": "VLAN",
			"tag": 4093,
			"mtu": 1500,
			"interfaces": [
                {
                    "name": "1.2",
                    "tagged": true
			    }
            ]
		},
		"internal-self": {
			"class": "SelfIp",
			"address": "{{{ SELF_IP_INTERNAL }}}",
			"vlan": "internal",
			"allowService": "none",
			"trafficGroup": "traffic-group-local-only"
		}
	}
}
```

**Telemetry Streaming Declaration Example**
- See https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/ for more information.
- Modify filter to match correct application insight name.

```json
{
    "Azure_Consumer": {
        "appInsightsResourceName": "dd-app-*",
        "class": "Telemetry_Consumer",
        "maxBatchIntervalMs": 5000,
        "maxBatchSize": 250,
        "trace": true,
        "type": "Azure_Application_Insights",
        "useManagedIdentity": true
    },
    "Bigip_Poller": {
        "actions": [
            {
                "includeData": {},
                "locations": {
                    "system": {
                        "cpu": true,
                        "networkInterfaces": {
                            "1.0": {
                                "counters.bitsIn": true
                            }
                        }
                    }
                }
            }
        ],
        "class": "Telemetry_System_Poller",
        "interval": 60
    },
    "class": "Telemetry"
}
```

**Application Services 3 (AS3) Declaration Example**
- See https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/ for more information.
- AS3 declaration which supports WAF deployments.

```json
{
    "action": "deploy",
    "class": "AS3",
    "declaration": {
        "Sample_http_01": {
            "A1": {
                "My_ASM_Policy": {
                    "class": "WAF_Policy",
                    "ignoreChanges": true,
                    "url": "https://raw.githubusercontent.com/F5Networks/f5-azure-arm-templates-v2/v1.3.1.0/examples/autoscale/bigip-configurations/Rapid_Deployment_Policy_13_1.xml"
                },
                "class": "Application",
                "serviceMain": {
                    "class": "Service_HTTP",
                    "policyWAF": {
                        "use": "My_ASM_Policy"
                    },
                    "pool": "webPool",
                    "virtualAddresses": [
                        "10.0.1.10"
                    ],
                    "virtualPort": 80
                },
                "template": "http",
                "webPool": {
                    "class": "Pool",
                    "members": [
                        {
                            "serverAddresses": [
                                "10.0.0.2"
                            ],
                            "servicePort": 80
                        }
                    ],
                    "monitors": [
                        "http"
                    ]
                }
            },
            "class": "Tenant"
        },
        "class": "ADC",
        "label": "Sample 1",
        "remark": "HTTP with custom persistence",
        "schemaVersion": "3.0.0"
    },
    "persist": true
}
```
## Resource Creation Flow Chart

![Resource Creation Flow Chart](https://github.com/F5Networks/f5-azure-arm-templates-v2/blob/v1.3.1.0/examples/images/azure-bigip-standalone-module.png)

