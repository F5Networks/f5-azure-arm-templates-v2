#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 180


echo "Verifying active device is shut down"
response=$(az vm show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm01 -d | jq -r .powerState)

if echo $response | grep 'stopped'; then
    echo "SUCCESS"
fi