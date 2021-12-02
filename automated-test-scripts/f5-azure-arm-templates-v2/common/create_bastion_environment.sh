#  expectValue = "Template validation succeeded"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'

if [[ "<PROVISION PUBLIC IP>" == "True" ]]; then 
    echo "Template validation succeeded"
fi

# download and use --template-file because --template-uri is limiting
TEMPLATE_FILE=${TMP_DIR}/<RESOURCE GROUP>-bastion-env.json
curl -k file://$PWD/examples/modules/bastion/bastion.json -o ${TEMPLATE_FILE}

SSH_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewpt-public | jq .value --raw-output)
SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value[1]')
echo "SUBNET_ID is "
echo $SUBNET_ID

CREATE_AUTOSCALE=False
if echo "<TEMPLATE URL>" | grep "autoscale"; then
    CREATE_AUTOSCALE=True
fi

DEPLOY_PARAMS='{"adminUsername":{"value":"azureuser"},"createAutoscaleGroup":{"value":'$CREATE_AUTOSCALE'},"instanceName":{"value":"<RESOURCE GROUP>"},"instanceType":{"value":"Standard_D2s_v3"},"nsgId":{"value":""},"sshKey":{"value":"'"${SSH_KEY}"'"},"subnetId":{"value":"'"${SUBNET_ID}"'"},"vmScaleSetMaxCount":{"value":1},"vmScaleSetMinCount":{"value":1}}'

DEPLOY_PARAMS_FILE=${TMP_DIR}/deploy_params.json

# save deployment parameters to a file, to avoid weird parameter parsing errors with certain values
# when passing as a variable. I.E. when providing an sshPublicKey
echo ${DEPLOY_PARAMS} > ${DEPLOY_PARAMS_FILE}

echo "DEBUG: DEPLOY PARAMS"
echo ${DEPLOY_PARAMS}

VALIDATE_RESPONSE=$(az deployment group validate --resource-group <RESOURCE GROUP> --template-file ${TEMPLATE_FILE} --parameters @${DEPLOY_PARAMS_FILE})
VALIDATION=$(echo ${VALIDATE_RESPONSE} | jq .properties.provisioningState)
if [[ $VALIDATION == \"Succeeded\" ]]; then
    az deployment group create --verbose --no-wait --template-file ${TEMPLATE_FILE} -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-env --parameters @${DEPLOY_PARAMS_FILE}
    echo "Template validation succeeded"
else
    echo "Template validation failed: ${VALIDATE_RESPONSE}"
fi
