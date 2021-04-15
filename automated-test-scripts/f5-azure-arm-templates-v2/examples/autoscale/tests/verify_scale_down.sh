#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 180

CAPACITY=$(az vmss show -g <RESOURCE GROUP> -n <RESOURCE GROUP>-vmss | jq -r .sku.capacity)
echo "CAPACITY: ${CAPACITY}"

# Check that only one device is present in the scale set
if [[ $CAPACITY == "1" ]]; then
     echo "Succeeded"
fi