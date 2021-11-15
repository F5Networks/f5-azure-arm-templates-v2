#  expectValue = "SUCCESS"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


echo "Restarting previously active device"
response=$(az vm start -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm01 --no-wait)

echo "SUCCESS"
