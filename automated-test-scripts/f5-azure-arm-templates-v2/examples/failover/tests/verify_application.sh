#  expectValue = "SUCCESS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 180


if [[ "<PROVISION APP>" == "False" ]]; then
    echo "SUCCESS"
else
    application_public_ip=$(az deployment group show -g <RESOURCE GROUP> -n <RESOURCE GROUP> | jq -r '.properties.outputs["vip1PublicIp"].value')

    echo "Application Public IP: $application_public_ip"
    httpsResponse=$(curl -sk https://$application_public_ip)
    httpResponse=$(curl -sk http://$application_public_ip)

    if echo ${httpsResponse} | grep -q "Demo" && echo ${httpResponse} | grep -q "Demo"; then
        echo "SUCCESS"
    fi
fi