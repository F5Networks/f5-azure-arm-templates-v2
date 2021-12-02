#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 180


TMP_DIR='/tmp/<DEWPOINT JOB ID>'

# supports utility license only atm
running_macs=`az vmss nic list -g <RESOURCE GROUP> --vmss-name <RESOURCE GROUP>-bigip-vmss | jq -r '.[] | select(.provisioningState=="Succeeded")' | jq -r .macAddress | tr -s '-' ':' | sort -f`
running_macs=$(echo "$running_macs" | tr '[:upper:]' '[:lower:]')
echo "Running MACs: ${running_macs}"

if [[ "<LICENSE TYPE>" == "bigiq" ]]; then
    if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
        echo "Found existing BIG-IQ"
        cat ${TMP_DIR}/bigiq_info.json
        bigiq_stack_name=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_name)
        bigiq_stack_region=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_region)
        bigiq_password=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_password)
    fi
    bigiq_address=$(aws cloudformation describe-stacks --region $bigiq_stack_region --stack-name $bigiq_stack_name | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="device1ManagementEipAddress")|.OutputValue')

    auth_token=`curl -ks -X POST -d '{"username":"admin", "password":"'"${bigiq_password}"'", "loginProviderName":"local"}' https://${bigiq_address}/mgmt/shared/authn/login | jq -r .token.token`

    production_key=`curl -sk -H "X-F5-Auth-Token: $auth_token" https://${bigiq_address}/mgmt/cm/device/licensing/pool/utility/licenses/ | jq -r '.items[] | select(.name=="production")' | jq -r .regKey`
    offer_id=`curl -sk -H "X-F5-Auth-Token: $auth_token" https://${bigiq_address}/mgmt/cm/device/licensing/pool/utility/licenses/${production_key}/offerings | jq -r '.items[] | select(.name=="F5-BIG-MSP-BT-1G")' | jq -r .id`

    licensed_macs=`curl -sk -H "X-F5-Auth-Token: $auth_token" https://${bigiq_address}/mgmt/cm/device/licensing/pool/utility/licenses/${production_key}/offerings/${offer_id}/members | jq -r '.items[] | select((.status=="LICENSED") and (.tenant | startswith("<DEWPOINT JOB ID>")))' | jq -r .macAddress | sort -f`
    licensed_macs=$(echo "$licensed_macs" | tr '[:upper:]' '[:lower:]')
    echo "Licensed MACs: ${licensed_macs}"

    if [[ ${running_macs} == ${licensed_macs} ]]; then
        echo "Succeeded"
    else
        echo "Failed"
    fi
else 
    echo "Succeeded"
fi