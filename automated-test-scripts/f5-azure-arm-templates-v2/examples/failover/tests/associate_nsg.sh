#  expectValue = "Succeeded"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0


# associating NSGs to subnets is needed to make failover work due to bug in Azure Fast Path
# azure support incident ID: 364674860
if echo "<TEMPLATE URL>" | grep -q "existing"; then
    vnet_name='vnet-<DEWPOINT JOB ID>'
else 
    vnet_name='<RESOURCE GROUP>-vnet'
fi

MGMT_ASS=$(az network vnet subnet update -g <RESOURCE GROUP> -n subnet-01 --vnet-name ${vnet_name} --network-security-group <RESOURCE GROUP>-nsg-01 | jq -r .provisioningState)
echo "MGMT_ASS: $MGMT_ASS"

EXT_ASS=$(az network vnet subnet update -g <RESOURCE GROUP> -n subnet-02 --vnet-name ${vnet_name} --network-security-group <RESOURCE GROUP>-nsg-02 | jq -r .provisioningState)
echo "EXT_ASS: $EXT_ASS"

if echo "${MGMT_ASS}" | grep -q "Succeeded" && echo "${EXT_ASS}" | grep -q "Succeeded"; then
    echo "Succeeded"
else
    echo "Failed"
fi