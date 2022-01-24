#!/usr/bin/env bash
#  expectValue = "ILB SUCCESSFULLY CONFIGURED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


function verify_ilb() {
    local -n _arr=$1
    local ilb_object=$(az network lb show --resource-group <RESOURCE GROUP> -n dd-ilb-<DEWPOINT JOB ID> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${ilb_object} | jq -r .$r)
        if echo "$response" | grep -q "${_arr[$r]}"; then
            ilb_result="Property:${r},Value:${_arr[$r]},PASSED"
        else
            ilb_result="Property:${r},Value:${_arr[$r]},FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${ilb_result}${spacer}"
    done
    echo "$results"
}
response="FAILED"
# setup management public ip array using outputs as expected values
if [[ "<INTERNAL LOAD BALANCER NAME>" == "None" ]]; then
    response="ILB not created for test."
else
    declare -A ilb
    ilb[backendAddressPools\[\].id]=$(az deployment group show --name dd-dag-<DEWPOINT JOB ID> --resource-group dd-dag-<DEWPOINT JOB ID> | jq -r .properties.outputs.internalBackEndLoadBalancerId.value)
    ilb[frontendIpConfigurations\[\].privateIpAddress]=$(az deployment group show --name dd-dag-<DEWPOINT JOB ID> --resource-group dd-dag-<DEWPOINT JOB ID> | jq -r .properties.outputs.internalFrontEndLoadBalancerIp.value)
    ilb[loadBalancingRules\[\].protocol]=Tcp
    # Run array's through function
    response=$(verify_ilb "ilb")
fi

spacer=$'\n============\n'

if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED${spacer}${response}"
else
    echo "ILB SUCCESSFULLY CONFIGURED${spacer}${response}"
fi