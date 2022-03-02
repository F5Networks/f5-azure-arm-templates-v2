#  expectValue = "Template validation succeeded"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'

# download and use --template-file because --template-uri is limiting
TEMPLATE_FILE=${TMP_DIR}/<RESOURCE GROUP>.json
curl -k file://$PWD/examples/modules/dag/dag.json -o ${TEMPLATE_FILE}

SUBNETID=""
if [[ "<INTERNAL LOAD BALANCER NAME>" == "None" ]]; then
    echo 'Not creating ilb, subnet id not required'
else
    ID=$(az network vnet subnet show --resource-group dd-bigip-<DEWPOINT JOB ID> --name subnet0 --vnet-name vnet-<DEWPOINT JOB ID> | jq -r .id)
    SUBNETID=",\"internalSubnetId\":{\"value\":\"${ID}\"}"
fi
PORTARRAY=""
if [[ '<LOAD BALANCER RULE PORTS>' == '[]' ]]; then
    echo 'Not creating elb, app ports not required'
else
    PORTARRAY=",\"loadBalancerRulePorts\":{\"value\":<LOAD BALANCER RULE PORTS>}"
fi


DEPLOY_PARAMS='{"nsg0":{"value":<NSG0>},"nsg1":{"value":<NSG1>},"nsg2":{"value":<NSG2>},"nsg3":{"value":<NSG3>},"nsg4":{"value":<NSG4>},"numberPublicMgmtIpAddresses":{"value":<NUMBER PUBLIC MGMT IP ADDRESSES>},"numberPublicExternalIpAddresses":{"value":<NUMBER PUBLIC EXT IP ADDRESSES>},"uniqueString":{"value":"<DNSLABEL>"},"externalLoadBalancerName":{"value":"<EXTERNAL LOAD BALANCER NAME>"},"internalLoadBalancerName":{"value":"<INTERNAL LOAD BALANCER NAME>"}'${SUBNETID}''${PORTARRAY}'}'

DEPLOY_PARAMS_FILE=${TMP_DIR}/deploy_params.json

# save deployment parameters to a file, to avoid weird parameter parsing errors with certain values
# when passing as a variable. I.E. when providing an sshPublicKey
echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}

echo "DEBUG: DEPLOY PARAMS"
echo ${DEPLOY_PARAMS}

VALIDATE_RESPONSE=$(az deployment group validate --resource-group <RESOURCE GROUP> --template-file ${TEMPLATE_FILE} --parameters @${DEPLOY_PARAMS_FILE})
VALIDATION=$(echo ${VALIDATE_RESPONSE} | jq .properties.provisioningState)
if [[ $VALIDATION == \"Succeeded\" ]]; then
    az deployment group create --verbose --no-wait --template-file ${TEMPLATE_FILE} -g <RESOURCE GROUP> -n <RESOURCE GROUP>-dag-env --parameters @${DEPLOY_PARAMS_FILE}
    echo "Template validation succeeded"
else
    echo "Template validation failed: ${VALIDATE_RESPONSE}"
fi
