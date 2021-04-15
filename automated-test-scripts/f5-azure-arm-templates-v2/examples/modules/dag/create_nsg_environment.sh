#  expectValue = "NSG Successfully Created"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

## Create security Group if required by test
if [ "<MGMT NSG>" == "Default" ] || [ "<MGMT NSG>" == "None" ]; then
    echo "mgmt security group not required"
    mgmt_result="Succeeded"
else    
    mgmt_result=$(az network nsg create -g <RESOURCE GROUP> -n <MGMT NSG> --tags creator[dewdrop] delete[True] | jq .NewNSG.provisioningState)
fi

if [ "<EXTERNAL NSG>" == "Default" ] || [ "<EXTERNAL NSG>" == "None" ]; then
    echo "app security group not required"
    app_result="Succeeded"
else    
    app_result=$(az network nsg create -g <RESOURCE GROUP> -n <EXTERNAL NSG> --tags creator[dewdrop] delete[True] | jq .NewNSG.provisioningState)
fi

if echo $mgmt_result | grep 'Succeeded' && echo $app_result | grep 'Succeeded'; then
    echo "NSG Successfully Created"
else
    echo "Failed: ${mgmt_result}, ${app_result}"
fi