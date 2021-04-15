#!/usr/bin/env bash
#  expectValue = "ELB SUCCESSFULLY CONFIGURED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


function verify_elb() {
    local -n _arr=$1
    local elb_object=$(az network lb show --resource-group <RESOURCE GROUP> -n dd-elb-<DEWPOINT JOB ID> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${elb_object} | jq -r .$r)
        if echo "$response" | grep -q "${_arr[$r]}"; then
            elb_result="Property:${r},Value:${_arr[$r]},PASSED"
        else
            elb_result="Property:${r},Value:${_arr[$r]},FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${elb_result}${spacer}"
    done
    echo "$results"
}
response="FAILED"
# setup management public ip array using outputs as expected values
if [[ "<EXTERNAL LOAD BALANCER NAME>" == "None" ]]; then
    response="ELB not created for test."
else
    declare -A elb
    # verify backendAddressPools and inbound nat pools
    elb[backendAddressPools\[\].id]=$(az deployment group show --name dd-dag-<DEWPOINT JOB ID> --resource-group dd-dag-<DEWPOINT JOB ID> | jq -r .properties.outputs.externalBackEndLoadBalancerID.value)
    if [[ <NUMBER PUBLIC MGMT IP ADDRESSES> -gt 0 ]]; then
        elb[backendAddressPools\[\].id]=$(az deployment group show --name dd-dag-<DEWPOINT JOB ID> --resource-group dd-dag-<DEWPOINT JOB ID> | jq -r .properties.outputs.externalBackEndMgmtLoadBalancerID.value)
        elb[inboundNatPools\[0\].backendPort]=22
        elb[inboundNatPools\[1\].backendPort]=8443
    fi
    # verify frontendIpConfigurations
    upperappip=$((<NUMBER PUBLIC EXT IP ADDRESSES>-1))
    for ((i=0; i<=upperappip; i++));
        do
            elb[frontendIpConfigurations\[${i}\].id]=$(az deployment group show --name dd-dag-<DEWPOINT JOB ID> --resource-group dd-dag-<DEWPOINT JOB ID> | jq -r .properties.outputs.externalFrontEndLoadBalancerID.value[${i}])
        done
    
    # verify probes and loadbalancing rules
    portarray=($(echo "<LOAD BALANCER RULE PORTS>" | tr -d '[]' | tr ',' ' '))
    arraylength=${#portarray[@]}
    upperprobe=$((${arraylength}-1))
    for ((i=0; i<=upperprobe; i++));
        do
            elb[probes\[${i}\].id]=$(az deployment group show --name dd-dag-<DEWPOINT JOB ID> --resource-group dd-dag-<DEWPOINT JOB ID> | jq -r .properties.outputs.externalLoadBalancerProbesID.value[${i}])
            elb[loadBalancingRules\[${i}\].id]=$(az deployment group show --name dd-dag-<DEWPOINT JOB ID> --resource-group dd-dag-<DEWPOINT JOB ID> | jq -r .properties.outputs.externalLoadBalancerRulesID.value[${i}])
        done
    
    # Run array's through function
    response=$(verify_elb "elb")
fi

spacer=$'\n============\n'
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "ELB SUCCESSFULLY CONFIGURED ${spacer}${response}"
fi