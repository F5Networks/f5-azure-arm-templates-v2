#  expectValue = "Template validation succeeded"
#  expectFailValue = "Template validation failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

TMP_DIR='/tmp/<DEWPOINT JOB ID>'

if [[ "<PROVISION PUBLIC IP>" == "True" ]]; then 
    echo "Template validation succeeded"
else
    # download and use --template-file because --template-uri is limiting
    TEMPLATE_FILE=${TMP_DIR}/<RESOURCE GROUP>-bastion-env.json
    curl -k file://$PWD/examples/modules/bastion/bastion.json -o ${TEMPLATE_FILE}

    SSH_KEY=$(az keyvault secret show --vault-name dewdropKeyVault -n dewpt-public | jq .value --raw-output)

    az network nsg create -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-nsg
    az network nsg rule create -g <RESOURCE GROUP> --nsg-name <RESOURCE GROUP>-bastion-nsg -n <RESOURCE GROUP>-bastion-nsg-rule --priority 100 --source-address-prefixes '*' --destination-port-ranges 22 --access Allow --protocol Tcp
    NSG_ID=$(az network nsg show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-nsg | jq -r .id)

    if echo "<TEMPLATE URL>" | grep "autoscale"; then
        CREATE_AUTOSCALE=True
        PUBLIC_IP_ID=''
        SUBNET_INDEX=1
    else
        CREATE_AUTOSCALE=False
        az network public-ip create -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-pip  --allocation-method Static --zone 1 --sku Standard
        PUBLIC_IP_ID=$(az network public-ip show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-pip | jq -r .id)
        SUBNET_INDEX=0
    fi
    SUBNET_ID=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq -r '.properties.outputs["subnets"].value['${SUBNET_INDEX}']')

    echo "NSG_ID is "
    echo $NSG_ID
    echo "PUBLIC_IP_ID is "
    echo $PUBLIC_IP_ID
    echo "SUBNET_ID is "
    echo $SUBNET_ID

    DEPLOY_PARAMS='{"adminUsername":{"value":"azureuser"},"createAutoscaleGroup":{"value":'$CREATE_AUTOSCALE'},"instanceName":{"value":"<RESOURCE GROUP>"},"instanceType":{"value":"Standard_D2s_v3"},"nsgId":{"value":"'"${NSG_ID}"'"},"sshKey":{"value":"'"${SSH_KEY}"'"},"subnetId":{"value":"'"${SUBNET_ID}"'"},"publicIpId":{"value":"'"${PUBLIC_IP_ID}"'"},"vmScaleSetMaxCount":{"value":1},"vmScaleSetMinCount":{"value":1}}'

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
fi
