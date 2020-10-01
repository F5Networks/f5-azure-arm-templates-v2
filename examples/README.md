
# Example Templates

- [Example Templates](#example-templates)
  - [Introduction](#introduction)
  - [Template Types](#template-types)
    - [Solution Parent Templates](#solution-parent-templates)
    - [Modules](#modules)
  - [Usage](#usage)
  - [BIG-IP Configuration](#big-ip-configuration)
  - [Cloud Configuration](#cloud-configuration)
  - [Getting Help](#getting-help)
    - [Filing Issues](#filing-issues)

## Introduction

The examples here leverage the modular [linked templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/linked-templates) design to provide maximum flexibility when authoring solutions using F5 BIG-IP.  

Example deployments use parent templates to deploy child templates (or modules) to facilitate quickly standing up entire stacks (complete with **example** network, application, and BIG-IP tiers). 

As a basic framework, an example full stack deployment may consist of: 

- **(Parent) Solution Template** (ex. Quickstart, Failover or Autoscale)
  -  **(Child) Network Template** - which creates virtual networks, subnets, and network security groups. 
  -  **(Child) Application Template** - which creates a generic application, based on the f5-demo-app container, for demonstrating live traffic through the BIG-IP.
  -  **(Child) DAG/Ingress Template** -  which creates resources required to get traffic to the BIG-IP.
  -  **(Child) Access Template** - which creates Identity and Acccess related resources, like a secret in cloud vault that can be referenced by F5 BIG-IP.
  -  **(Child) Function Template** - which creates an Azure function to manage licenses for an Azure Virtual Machine Scale Set of BIG-IP instances licensed with BIG-IQ.
  -  **(Child) BIG-IP Autoscale Template** *(existing-stack)* - which creates BIG-IP instance(s)in an Azure Virtual Machine Scale Set.

***Disclaimer:*** F5 does not require or have any recommendations on leveraging linked stacks in production. They are used here simply to provide useful tested/validated examples and illustrate various solutions' resource dependencies, configurations, etc., which you may want or need to customize, regardless of the deployment method used. 
 

## Template Types

Templates are grouped into the following categories:

### Solution Parent Templates

  - **Quickstart (Planned)**: <br> These parent templates deploy a collection of linked child templates to create a standalone BIG-IP VE in an example full-stack. Standalone BIG-IP VEs are primarily used for Dev/Test/Staging, replacing/upgrading individual instances in traditional failover clusters, and/or manually scaling out. <br>

  - **Failover Cluster (Planned)**: <br> These parent templates deploys more than one BIG-IP VE in a ScaleN cluster (a traditional High Availability Pair in most cases), as well as the full stack of resources required by the solution. Failover clusters are primarily used to replicate traditional Active/Standy BIG-IP deployments. In these deployments an individual BIG-IP VE in the cluster owns or is Active for) a particular IP address. For example, the BIG-IP VEs will fail over services from one instance to another by remapping IP addresses, routes, etc. based on Active/Standby status. Failover is implemented either via API (API calls to the cloud platform vs network protocols like Gratuitous ARP, route updates, and so on), or via an upstream service (like a native loud balancer) which will only send traffic to the active instance for that service based on a health monitor. In all cases, a single BIG-IP VE will be active for a single IP address.

  - **Autoscale** <br> These parent templates deploy a collection of linked child templates to create a Virtual Machine Scale Set (VMSS) of BIG-IP VE instances that scale in and out based on thresholds you configure in the template, as well as the full stack of resources required by the solution. The BIG-IP VEs are "All Active" and are primarily used to scale an L7 service on a single wildcard virtual (although you can add additional services using ports).<br> Unlike previous solutions, this solution leverages the more traditional autoscale configuration management pattern where each instance is created with an identical configuration as defined in the Scale Set's "model". Scale Set sizes are no longer restricted to the smaller limitations of the BIG-IP's cluster. The BIG-IP's configuration, now defined in a single convenient yaml-based [F5 BIG-IP Runtime Init](https://github.com/f5devcentral/f5-bigip-runtime-init) configuration file, leverages [F5 Automation Tool Chain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) declarations which are easier to author, validate and maintain as code. For instance, if you need to change the configuration on the instances in the deployment, you update the the "model" by passing the new config version via the template's *runtimeConfig* input parameter. The Scale Set provider will update the instances to the new model according to its rolling update policy. Web Application Firewall (WAF) functionality is provisioned using Declarative Onboarding declaration and configured via an Application Services declaration. Example F5 BIG-IP Runtime Init configurations and Automation Toolchain component declarations are available in the Autoscale examples folder. 

### Modules

  - These child templates create the Azure resources that compose a full stack deployment. They are referenced as linked deployment resources from the solution parent templates (Quickstart, Failover, Autoscale, etc).<br>
  The parent templates manage passing inputs to the child templates and using their outputs as inputs to other child templates.<br>

    #### Module Types:
      - **Network**: Use this template to create a reference network stack. This template creates virtual networks, subnets, and network security groups. 
      - **Application**: Use this template to deploy an example application. This template creates a generic application, based on the f5-demo-app container, for demonstrating live traffic through the BIG-IP. You can specify a different container or application to use when deploying the example template.
      - **Disaggregation/Ingress** (DAG): Use these templates to create resources required to get or distribute traffic to the BIG-IP instance(s). For example: Azure Public IP Addresses, internal/external Load Balancers, and accompanying resources such as load balancing rules, NAT rules, and probes.
      - **Access**: Use these templates to create a Identity and Access related resources required for the solution.  These templates create an Azure Managed User Identity, KeyVault, and secret that can be referenced in the F5 BIG-IP Runtime Init configuration file. The secret can store sensitive information such as the BIG-IP password, BIG-IQ password, or Azure service principal access key for use in service discovery. 
      - **Function**: Use these templates to create an Azure function, hosting plan, and other resources required to automatically revoke a BIG-IP license assignment from BIG-IQ when the capacity of the Virtual Machine Scale Set is reduced due to deallocation of a BIG-IP instance.
      - **BIG-IP**: Use these templates to create the BIG-IP Virtual Machine instance(s). For example, a standalone VM or a Virtual Machine Scale Set. The BIG-IP modules can be used independently from the linked stack examples here (ex. in an "existing-stack").<br><br> In the Autoscale example, the required Autoscale Settings and Application Insights resources are also created.
          

## Usage

Navigate to the parent solution template directory:

Examples: 
* autoscale/payg
* autoscale/bigiq

To launch the parent template, either 
1. Click the blue "Deploy to Azure" button and fill in the parameters in Azure's Portal

OR

2. Edit the *paramaters.json file and launch via CLI.
  ex.
  ```
  az group create -l westus -n my-rg
  az deployment group create --name my-parent --resource-group my-rg --template-file azuredeploy.json  --parameters azuredeploy.parameters.json
  ```

See the specific parent template's README for full details. 


## BIG-IP Configuration

You will most likely want or need to change the BIG-IP configuration. This generally involves customizing the startup script via the [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) configuration and any Automation Tool Chain declarations it is referencing. See [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) for more details on how to customize the configuration.  Once these configuration files are modified, they need to be published to a routable location the BIG-IPs have access to download at deploy time (typically: a version control system, local/private file server/service, etc). 

You will then modify the `runtimeConfig` template parameter to reference the new Runtime Init configuration.


## Cloud Configuration 

In addition to changing the BIG-IP Configuration, you may want to customize the cloud resources, which involves editing the templates themselves.  

The guiding principal of composing modules was grouping related objects that fell into different administrative domains and facilitating re-usability without degrading into one-to-one mappings. For example, if the team deploying BIG-IP doesn't have permission to create IAM roles, they can point a security team to the ACCESS module for an example of the permissions needed. If customizing, users may certainly choose to decompose even further or recompose/re-group into simpler single templates.  For example, depending on what resource creation permissions users have, that same team may want to create a single dependencies module of resources they do have permissions for, found in various dependency modules like DAG and FUNCTION, and just reference the existing role the security team provided. Or if all dependencies are provided, a user may just want to use the BIG-IP template by itself. 

A high level overview of customizing the templates may look like:


1. Clone or fork the repository
    ```
    git clone git@github.com:f5networks/f5-azure-arm-templates-v2.git  
    ```
    *Optional*: Create a custom branch
    
    git checkout -b \<branch\>
    ```
    git checkout -b customizations
    ```

2. Edit the templates themselves

    Commit changes
    ```
    git add <FILES_MODIFIED>
    git commit -m "customizations added"
    ```

3. Publish the templates to an HTTP or HTTPS location reachable by Azure Resource Manager (ex. github, Azure Storage, etc). See URI requirements here: https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/linked-templates#linked-template and your hosting service's publishing documentation.

    Examples:

    #### Github

      - If you cloned the repo, create a repo in your own account
        ```
        curl -u USERNAME:PASSWORD https://api.github.com/user/repos -d '{"name":"f5-azure-arm-templates-v2"}'
        ```
      - Add your newly created repo as a remote
        ```
        git remote add myRemote git@github.com:<YOURACCOUNTHERE>/f5-azure-arm-templates-v2.git
        ```
      - Publish to your new remote repo
        ```
        git push myRemote <branch>
        ```
    
      For more details, see [here](https://docs.github.com/en/free-pro-team@latest/github/importing-your-projects-to-github/adding-an-existing-project-to-github-using-the-command-line) or github's [documentation](https://docs.github.com/).


    #### Azure Storage

      - Upload templates to Azure storage (from the directory containing the f5-azure-arm-templates-v2/ repo):
        - az group create -n [RESOURCE GROUP] -l [REGION]
        - az storage account create -n [STORAGE ACCOUNT NAME] -g [RESOURCE GROUP] -l [REGION]
        - az storage container create -n [CONTAINER NAME] --account-name [STORAGE ACCOUNT NAME]  --public-access container
        - az storage blob upload-batch -s f5-azure-arm-templates-v2/ -d https://[STORAGE ACCOUNT NAME].blob.core.windows.net/[CONTAINER NAME]

        ex.
        ```
        az group create -l westus -n custom-templates-group
        az storage account create -n customtmpltsacct -g custom-templates-group -l westus --sku Standard_LRS
        az storage container create --name customizations --account-name customtmpltsacct --public-access container
        az storage blob upload-batch -s f5-azure-arm-templates-v2/ -d https://customtmpltsacct.blob.core.windows.net/customizations
        ```
      - ***WARNING: This particular example will upload the entire git repository folder to Azure storage. If containing any sensitive information (ex. from .gitignore, custom files), you should remove those.***

 1. Update the template parameters ``templateBaseUrl`` and ``artifactLocation`` to reference the custom location. These must combine to resolve to the location containing the ``modules/`` folder.

    Examples:

    #### Github
    Modules location: https://raw.githubusercontent.com/myAccount/f5-azure-arm-templates-v2/customizations/examples/modules
      ``` 
          "templateBaseUrl": {
            "value": "https://raw.githubusercontent.com/myAccount/f5-azure-arm-templates-v2/"
          },
          "artifactLocation": {
            "value": "customizations/examples/"
          },
      ```

    #### Azure Storage
    Modules location: https://customtmpltsacct.blob.core.windows.net/customizations/examples/modules
      ```
          "templateBaseUrl": {
            "value": "https://customtmpltsacct.blob.core.windows.net/"
          },
          "artifactLocation": {
            "value": "customizations/examples/"
          }
      ```

4. Launch custom templates from new location


## Getting Help

Due to the heavy customization requirements of external cloud resources and BIG-IP configurations in these solutions, F5 does not provide technical support for deploying, customizing, or troubleshooting the templates themselves. However, the various underlying products and components used (for example: F5 BIG-IP Virtual Edition, F5 BIG-IP Runtime Init, Automation Toolchain extensions, and Cloud Failover Extension (CFE)) in the solutions located here are F5-Supported and capable of being deployed with other orchestration tools. Read more about [Support Policies](https://www.f5.com/company/policies/support-policies). Problems found with the templates deployed as-is should be reported via a GitHub issue.


For help with authoring and support for custom CST2 templates, we recommend engaging F5 Professional Services (PS).


### Filing Issues

If you find an issue, we would love to hear about it.

- Use the **[Issues](https://github.com/F5Networks/f5-azure-arm-templates-v2/issues)** link on the GitHub menu bar in this repository for items such as enhancement, feature requests and bug fixes. Tell us as much as you can about what you found and how you found it.