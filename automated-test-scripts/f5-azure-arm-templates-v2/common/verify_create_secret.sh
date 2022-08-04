#  expectValue = "Succeeded"
#  expectFailValue = "Failed"
#  scriptTimeout = 12
#  replayEnabled = true
#  replayTimeout = 5


result=$(az keyvault show --resource-group <RESOURCE GROUP> --name <RESOURCE GROUP>fv | jq -r .properties.provisioningState)

if echo $result | grep Succeeded; then
    echo $result
fi