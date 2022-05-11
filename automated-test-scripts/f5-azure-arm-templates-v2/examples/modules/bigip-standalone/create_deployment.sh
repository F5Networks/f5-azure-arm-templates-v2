#  expectValue = "Template validation succeeded"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'

# download and use --template-file because --template-uri is limiting
TEMPLATE_FILE=${TMP_DIR}/<RESOURCE GROUP>.json
curl -k <TEMPLATE URL> -o ${TEMPLATE_FILE}
echo "TEMPLATE URI: <TEMPLATE URL>"
SSH_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewpt-public | jq .value --raw-output)

# mgmt networking section - subnet ID and self IP are required
MGMT_SUBNET_ID="\"mgmtSubnetId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-net-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.subnets.value[0])\"}"
MGMT_SELF_IP="\"mgmtSelfIp\":{\"value\":\"<SELF IP MGMT>\"},"
MGMT_PUBLIC_IP_ID=""
MGMT_NSG_ID=""

if [[ "<NUMBER PUBLIC MGMT IP ADDRESSES>" -gt "0" ]]; then
    MGMT_PUBLIC_IP_ID="\"mgmtPublicIpId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.mgmtIpIds.value[0])\"},"
fi

if [[ "<NSG0>" != "[]" ]]; then  
    MGMT_NSG_ID="\"mgmtNsgId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.nsgIds.value[0])\"},"
fi

# nic1 networking section
# need to make sure you provision enough public IP addresses in params file; setting all files to 8 public IPs for now
PUBLIC_IP_IDS=$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.externalIpIds.value)
NIC1_SUBNET_ID=""
NIC1_PRIMARY_PUBLIC_IP_ID=""
NIC1_SELF_IP=""
NIC1_NSG_ID=""
if [[ "<NUMBER SUBNETS>" -gt "1" ]]; then 
    NIC1_SUBNET_ID="\"nic1SubnetId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-net-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.subnets.value[1])\"},"
    NIC1_SELF_IP="\"nic1SelfIp\":{\"value\":\"<SELF IP NIC1>\"},"
    if [[ "<NSG1>" != "[]" ]]; then  
        NIC1_NSG_ID="\"nic1NsgId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.nsgIds.value[1])\"},"
    fi
    if [[ "<PROVISION PRIMARY PUBLIC IPS>" == "Yes" ]]; then  
        NIC1_PRIMARY_PUBLIC_IP_ID="\"nic1PrimaryPublicId\":{\"value\":\"$(echo ${PUBLIC_IP_IDS} | jq -r .[0])\"},"
        PUBLIC_IP_IDS=$(echo ${PUBLIC_IP_IDS} | jq 'del(.[0])')
    fi
fi

# nic2 networking section
NIC2_SUBNET_ID=""
NIC2_PRIMARY_PUBLIC_IP_ID=""
NIC2_SELF_IP=""
NIC2_NSG_ID=""
if [[ "<NUMBER SUBNETS>" -gt "2" ]]; then 
    NIC2_SUBNET_ID="\"nic2SubnetId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-net-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.subnets.value[2])\"},"
    NIC2_SELF_IP="\"nic2SelfIp\":{\"value\":\"<SELF IP NIC2>\"},"
    if [[ "<NSG2>" != "[]" ]]; then  
        NIC2_NSG_ID="\"nic2NsgId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-dag-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.nsgIds.value[2])\"},"
    fi
    if [[ "<PROVISION PRIMARY PUBLIC IPS>" == "Yes" ]]; then  
        NIC2_PRIMARY_PUBLIC_IP_ID="\"nic2PrimaryPublicId\":{\"value\":\"$(echo ${PUBLIC_IP_IDS} | jq -r .[0])\"},"
        PUBLIC_IP_IDS=$(echo ${PUBLIC_IP_IDS} | jq 'del(.[0])')
    fi
fi

NIC1_SERVICE_IPS=""
if [[ "<SERVICE IPS NIC1>" != "[]" ]]; then
    NIC1_SERVICES='<SERVICE IPS NIC1>'
    NIC1_SERVICES="${NIC1_SERVICES/PIP0/$(echo ${PUBLIC_IP_IDS} | jq -r .[0])}" && PUBLIC_IP_IDS=$(echo ${PUBLIC_IP_IDS} | jq 'del(.[0])')
    NIC1_SERVICES="${NIC1_SERVICES/PIP1/$(echo ${PUBLIC_IP_IDS} | jq -r .[0])}" && PUBLIC_IP_IDS=$(echo ${PUBLIC_IP_IDS} | jq 'del(.[0])')
    NIC1_SERVICES="${NIC1_SERVICES/PIP2/$(echo ${PUBLIC_IP_IDS} | jq -r .[0])}" && PUBLIC_IP_IDS=$(echo ${PUBLIC_IP_IDS} | jq 'del(.[0])')
    NIC1_SERVICE_IPS="\"nic1ServiceIPs\":{\"value\":${NIC1_SERVICES}},"
fi

NIC2_SERVICE_IPS=""
if [[ "<SERVICE IPS NIC2>" != "[]" ]]; then
    NIC2_SERVICES='<SERVICE IPS NIC2>'
    NIC2_SERVICES="${NIC2_SERVICES/PIP0/$(echo ${PUBLIC_IP_IDS} | jq -r .[0])}" && PUBLIC_IP_IDS=$(echo ${PUBLIC_IP_IDS} | jq 'del(.[0])')
    NIC2_SERVICES="${NIC2_SERVICES/PIP1/$(echo ${PUBLIC_IP_IDS} | jq -r .[0])}" && PUBLIC_IP_IDS=$(echo ${PUBLIC_IP_IDS} | jq 'del(.[0])')
    NIC2_SERVICES="${NIC2_SERVICES/PIP2/$(echo ${PUBLIC_IP_IDS} | jq -r .[0])}" && PUBLIC_IP_IDS=$(echo ${PUBLIC_IP_IDS} | jq 'del(.[0])')
    NIC2_SERVICE_IPS="\"nic2ServiceIPs\":{\"value\":${NIC2_SERVICES}},"
fi

# identity section
ASSIGNMANAGEDIDENTITY=""
ROLEDEFINITIONID=""
TEMP_VAR="<USER ASSIGNED IDENT NAME>"
if [[ $TEMP_VAR =~ "USER ASSIGNED IDENT NAME" || -z $TEMP_VAR ]]; then
   ROLEDEFINITIONID="\"roleDefinitionId\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-access-env -g <RESOURCE GROUP> | jq -r .properties.outputs.roleDefinitionId.value)\"},"
else
   ASSIGNMANAGEDIDENTITY="\"userAssignManagedIdentity\":{\"value\":\"$(az deployment group show -n <RESOURCE GROUP>-access-env -g <RESOURCE GROUP> | jq  -r .properties.outputs.userAssignedIdentityId.value)\"},"
fi

# parameters section
DEPLOY_PARAMS='{"uniqueString":{"value":"<DNSLABEL>"},"adminUsername":{"value":"<ADMIN USERNAME>"},"sshKey":{"value":"'"$SSH_KEY"'"},"image":{"value":"<IMAGE>"},"instanceType":{"value":"<INSTANCE TYPE>"},"useAvailabilityZones":{"value":<USE AVAILABILITY ZONES>},"bigIpRuntimeInitConfig":{"value":"<RUNTIME CONFIG>"},"vmName":{"value":"<VM NAME>"},'${ASSIGNMANAGEDIDENTITY}''${ROLEDEFINITIONID}''${NIC2_SUBNET_ID}''${NIC2_PRIMARY_PUBLIC_IP_ID}''${NIC2_SELF_IP}''${NIC2_SERVICE_IPS}''${NIC2_NSG_ID}''${NIC1_SUBNET_ID}''${NIC1_PRIMARY_PUBLIC_IP_ID}''${NIC1_SELF_IP}''${NIC1_SERVICE_IPS}''${NIC1_NSG_ID}''${MGMT_NSG_ID}''${MGMT_PUBLIC_IP_ID}''${MGMT_SELF_IP}''${MGMT_SUBNET_ID}'}'
DEPLOY_PARAMS_FILE=${TMP_DIR}/deploy_params.json

# save deployment parameters to a file, to avoid weird parameter parsing errors with certain values
# when passing as a variable. I.E. when providing an sshPublicKey
echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}

echo "DEBUG: DEPLOY PARAMS"
echo ${DEPLOY_PARAMS}

VALIDATE_RESPONSE=$(az deployment group validate --resource-group <RESOURCE GROUP> --template-file ${TEMPLATE_FILE} --parameters @${DEPLOY_PARAMS_FILE})
VALIDATION=$(echo ${VALIDATE_RESPONSE} | jq .properties.provisioningState)
if [[ $VALIDATION == \"Succeeded\" ]]; then
    az deployment group create --verbose --no-wait --template-file ${TEMPLATE_FILE} -g <RESOURCE GROUP> -n <RESOURCE GROUP> --parameters @${DEPLOY_PARAMS_FILE}
    echo "Template validation succeeded"
else
    echo "Template validation failed: ${VALIDATE_RESPONSE}"
fi