#  expectValue = "Environment Successfully Created"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0

## Create storage account  
storage_account_name=$(echo st<RESOURCE GROUP>tmpl | tr -d -)
storage_account_fqdn=$(az storage account create -n ${storage_account_name} -g <RESOURCE GROUP> -l <REGION> | jq -r .primaryEndpoints.blob)

## Create container
storage_container=$(az storage container create -n templates --account-name ${storage_account_name} --public-access container | jq -r .created)

## Upload templates to container
upload_result=$(az storage blob upload-batch -d ${storage_account_fqdn}templates -s examples/)

if echo $upload_result | grep 'templates/README.md'; then
    echo "Environment Successfully Created"
else
    echo "Failed: ${upload_result}"
fi