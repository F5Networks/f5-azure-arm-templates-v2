#  expectValue = "Succeeded"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

STATUS=$(az identity create --name <USER ASSIGNED IDENT NAME> --resource-group <RESOURCE GROUP> --tags creator=dewdrop delete=True)
echo $STATUS | jq .


if [[ ! -z $STATUS ]]; then
    echo "Succeeded"
fi
