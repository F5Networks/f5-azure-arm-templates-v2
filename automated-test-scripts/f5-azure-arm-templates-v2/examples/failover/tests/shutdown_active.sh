#  expectValue = "SUCCESS"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


echo "Shutting down active device to force failover"
response=$(az vm stop -g <RESOURCE GROUP> -n <RESOURCE GROUP>-bigip-vm01 --no-wait)

echo "SUCCESS"