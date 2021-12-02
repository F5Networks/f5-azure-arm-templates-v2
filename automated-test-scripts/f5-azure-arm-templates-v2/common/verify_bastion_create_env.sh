#  expectValue = "Succeeded"
#  expectFailValue = "Failed"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 1800

if [[ "<PROVISION PUBLIC IP>" == "True" ]]; then 
    echo "Succeeded"
fi

# Limit output, only report provisioningState
az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bastion-env | jq .properties.provisioningState