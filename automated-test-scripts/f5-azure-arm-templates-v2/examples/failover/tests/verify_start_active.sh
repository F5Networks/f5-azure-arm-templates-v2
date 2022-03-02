#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 180


echo "Verifying previously active device is running"
response=$(az vm show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm01 -d | jq -r .powerState)

if echo $response | grep 'running'; then
    echo "SUCCESS"
fi