#!/usr/bin/env bash
#  expectValue = "SECURITY GROUP CREATION PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# Script Requires min BASH Version 4
# usage: verify_nsg_security_rule nsg_name associative_array filter
# Array: [rule]="expected_value"
function verify_nsg_security_rule() {
    local -n _arr=$2
    for r in "${!_arr[@]}";
    do
        local response=$(az network nsg show --resource-group <RESOURCE GROUP> --name ${1} | jq -r --arg name ${r} --arg filter ${3} '.securityRules[] | select(.name==$name) | .[$filter]')
        if echo "$response" | grep -q "${_arr[$r]}"; then
            rule_result="Rule:${r}:Value:${_arr[$r]}:PASSED"
        else
            rule_result="Rule:${r}:Value:${_arr[$r]}:FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${rule_result}${spacer}"
    done
    echo "$results"
}

# Build associative security group arrays
case "<NSG0>" in
"[]")
    declare -A nsg1_port_security_rules_inbound
    declare -A nsg1_destination_security_rule 
    declare -A nsg1_protocol ;;
*)
    declare -A nsg1_port_security_rules_inbound
    nsg1_port_security_rules_inbound[nsg_01_allow_0]="<NSG0 MGMT PORTS>"
    nsg1_port_security_rules_inbound[nsg_01_allow_1]="<NSG0 EXT PORTS>"

    declare -A nsg1_destination_security_rule
    nsg1_destination_security_rule[nsg_01_allow_0]="<NSG0 SOURCE>"
    nsg1_destination_security_rule[nsg_01_allow_1]="<NSG0 SOURCE>"

    declare -A nsg1_protocol
    nsg1_protocol[nsg_01_allow_0]="<NSG0 PROTOCOL>"
    nsg1_protocol[nsg_01_allow_1]="<NSG0 PROTOCOL>"

    nsg_to_test="<RESOURCE GROUP>-nsg-01" ;;
esac

case "<NSG1>" in
"[]")
    declare -A nsg2_port_security_rules_inbound
    declare -A nsg2_port_security_rules_outbound
    declare -A nsg2_destination_security_rule 
    declare -A nsg2_protocol ;;
*)
    declare -A nsg2_port_security_rules_inbound
    nsg2_port_security_rules_inbound[nsg_02_allow_0]="<NSG1 PORTS>"

    declare -A nsg2_port_security_rules_outbound
    nsg2_port_security_rules_outbound[allow_loadBalancer_traffic]="*"

    declare -A nsg2_destination_security_rule
    nsg2_destination_security_rule[nsg_02_allow_0]="<NSG1 SOURCE>"

    declare -A nsg2_protocol
    nsg2_protocol[nsg_02_allow_0]="<NSG1 PROTOCOL>"

    nsg_to_test="<RESOURCE GROUP>-nsg-02" ;;
esac

case "<NSG2>" in
"[]")
    declare -A nsg3_port_security_rules_inbound
    declare -A nsg3_port_security_rules_outbound
    declare -A nsg3_destination_security_rule 
    declare -A nsg3_protocol ;;
*)
    declare -A nsg3_port_security_rules_inbound
    nsg3_port_security_rules_inbound[nsg_03_allow_0]="<NSG2 PORTS>"

    declare -A nsg3_port_security_rules_outbound
    nsg3_port_security_rules_outbound[allow_loadBalancer_traffic]="*"

    declare -A nsg3_destination_security_rule
    nsg3_destination_security_rule[nsg_03_allow_0]="<NSG2 SOURCE>"

    declare -A nsg3_protocol
    nsg3_protocol[nsg_03_allow_0]="<NSG2 PROTOCOL>"

    nsg_to_test="<RESOURCE GROUP>-nsg-03" ;;
esac

# Run arrays through function
response=$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-01" "nsg1_port_security_rules_inbound" "destinationPortRanges")
response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-01" "nsg1_destination_security_rule" "sourceAddressPrefix")
response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-01" "nsg1_protocol" "protocol")

response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-02" "nsg2_port_security_rules_inbound" "destinationPortRanges")
response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-02" "nsg2_port_security_rules_outbound" "destinationPortRange")
response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-02" "nsg2_destination_security_rule" "sourceAddressPrefix")
response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-02" "nsg2_protocol" "protocol")

response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-03" "nsg3_port_security_rules_inbound" "destinationPortRanges")
response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-03" "nsg3_port_security_rules_outbound" "destinationPortRange")
response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-03" "nsg3_destination_security_rule" "sourceAddressPrefix")
response=${response}$(verify_nsg_security_rule "<RESOURCE GROUP>-nsg-03" "nsg3_protocol" "protocol")

spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "SECURITY GROUP CREATION PASSED ${spacer}${response}"
fi