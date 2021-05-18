#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 180

# supports utility license only atm
RUNNING_MACS=`az vmss nic list -g <RESOURCE GROUP> --vmss-name <RESOURCE GROUP>-bigip-vmss | jq -r '.[] | select(.provisioningState=="Succeeded")' | jq -r .macAddress | tr -s '-' ':' | sort -f`
echo "Running MACs: ${RUNNING_MACS}"

if [[ <LICENSE TYPE> == "bigiq" ]]; then
    BIGIQ_ADDRESS=`az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-env | jq '.properties.outputs["bigiqIp"].value' --raw-output | cut -d' ' -f1`
    CLPV2_KEY=`curl -sku 'azureuser:B!giq2017' https://${BIGIQ_ADDRESS}/mgmt/cm/device/licensing/pool/utility/licenses/ | jq -r '.items[] | select(.name=="clpv2")' | jq -r .regKey`
    OFFER_ID=`curl -sku 'azureuser:B!giq2017' https://${BIGIQ_ADDRESS}/mgmt/cm/device/licensing/pool/utility/licenses/${CLPV2_KEY}/offerings | jq -r '.items[] | select(.name=="F5-BIG-MSP-BT-1G")' | jq -r .id`
    LICENSED_MACS=`curl -sku 'azureuser:B!giq2017' https://${BIGIQ_ADDRESS}/mgmt/cm/device/licensing/pool/utility/licenses/${CLPV2_KEY}/offerings/${OFFER_ID}/members | jq -r '.items[] | select(.status=="LICENSED")' | jq -r .macAddress | sort -f`
    echo "Licensed MACs: ${LICENSED_MACS}"

    if [[ ${RUNNING_MACS} == ${LICENSED_MACS} ]]; then
        echo "Succeeded"
    else
        echo "Failed"
    fi
else 
    echo "Succeeded"
fi