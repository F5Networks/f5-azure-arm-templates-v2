#  expectValue = "Environment Successfully Created"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

## Create VNET  
vnet_result=$(az network vnet create -g <RESOURCE GROUP> -n <RESOURCE GROUP>-vnet --address-prefix 10.0.0.0/16 --subnet-name <RESOURCE GROUP> --subnet-prefix 10.0.0.0/24 --tags creator[dewdrop] delete[True] | jq .newVNet.provisioningState)

## Create VMSS
vmss_result=$(az vmss create -g <RESOURCE GROUP> -n <RESOURCE GROUP>-vmss --vnet-name <RESOURCE GROUP> --subnet <RESOURCE GROUP> --image UbuntuLTS --instance-count 0 --admin-username <USERNAME> --admin-password <PASSWORD> --tags creator[dewdrop] delete[True] | jq .vmss.provisioningState)

if echo $vnet_result | grep 'Succeeded' && echo $vmss_result | grep 'Succeeded'; then
    echo "Environment Successfully Created"
else
    echo "Failed: ${vnet_result}, ${vmss_result}"
fi