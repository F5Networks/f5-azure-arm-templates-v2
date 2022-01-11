#  expectValue = "Succeeded"
#  expectFailValue = "Failed"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 1800

if [[ "<PROVISION PUBLIC IP>" == "True" ]]; then 
    echo "Succeeded"
else
    # Limit output, only report provisioningState
    az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-env | jq .properties.provisioningState
fi