#  expectValue = "Succeeded"
#  expectFailValue = "Failed"
#  scriptTimeout = 15
#  replayEnabled = false
#  replayTimeout = 0


TMP_DIR='/tmp/<DEWPOINT JOB ID>'

SECRET_VALUE='<SECRET VALUE>'
if [[ "<LICENSE TYPE>" == "bigiq" ]]; then
    if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
        echo "Found existing BIG-IQ"
        cat ${TMP_DIR}/bigiq_info.json
		SECRET_VALUE=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_password)
    else
        echo "Failed - No BIG-IQ found"
    fi
fi

az keyvault create --location <REGION> \
	--name <RESOURCE GROUP>fv \
	--resource-group <RESOURCE GROUP> \
	--bypass AzureServices \
	--default-action Allow \
	--sku standard \
	--tags creator=dewdrop delete=True

az keyvault secret set --name <RESOURCE GROUP>bigiq \
	--vault-name  <RESOURCE GROUP>fv \
	--value ${SECRET_VALUE}