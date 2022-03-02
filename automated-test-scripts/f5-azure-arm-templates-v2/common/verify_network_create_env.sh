#  expectValue = "Succeeded"
#  expectFailValue = "Failed"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 1800

# Limit output, only report provisioningState
az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-net-env | jq .properties.provisioningState