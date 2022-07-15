#!/usr/bin/env bash
#  expectValue = "SUBNET CREATION PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# Script Requires min BASH Version 4
# usage: verify_subnet vnet_name associative_array filter
function verify_subnet() {
    local -n _arr=$2
    for r in "${!_arr[@]}";
    do
        local response=$(az network vnet subnet show --resource-group <RESOURCE GROUP> --name ${r} --vnet-name ${1} | jq -r .${3})
        if echo "$response" | grep -q "${_arr[$r]}"; then
            subnet_result="Subnet:${r}:Value:${_arr[$r]}:PASSED"
        else
            subnet_result="Subnet:${r}:Value:${_arr[$r]}:FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${subnet_result}${spacer}"
    done
    echo "$results"
}

# Build associative security group arrays
# Array: [subnet]="expected_value"
if [ <NUM SUBNETS> -gt 0 ]; then
    declare -A assigned_route_table
    declare -A assigned_nat_gw
    declare -A subnets
    upperlimit=$((<NUM SUBNETS>))
    for ((s=1; s<=upperlimit; s++));
        do         
            assigned_route_table[subnet-0${s}]="route-table-subnet-0${s}"
            subnets[subnet-0${s}]="<VNET ADDRESS PREFIX>"
        done

    if [ <CREATE NAT GATEWAY> == "True" ]; then
        assigned_nat_gw[subnet-01]="<VIRTUAL NETWORK NAME>"
    fi
fi

# Run arrays through function
spacer=$'\n============\n'
response=$(verify_subnet "<VIRTUAL NETWORK NAME>" "assigned_route_table" "routeTable.id")
response=${response}${spacer}$(verify_subnet "<VIRTUAL NETWORK NAME>" "assigned_nat_gw" "natGateway.id")
response=${response}${spacer}$(verify_subnet "<VIRTUAL NETWORK NAME>" "subnets" "addressPrefix")
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "SUBNET CREATION PASSED ${spacer}${response}"
fi