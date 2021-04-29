#  expectValue = "Succeeded"
#  expectFailValue = "Failed"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 1800

# Limit output, only report provisioningState
if [[ "<INTERNAL LOAD BALANCER NAME>" == "None" ]]; then
    echo "Succeeded: subnet for ilb not required"
else
az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-env | jq .properties.provisioningState
fi