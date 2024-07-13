#!/bin/bash

OUTPUT_FILE=${1:-"untagged_resources.csv"}
TAG_KEY=${2:-"SBO_Billing"}
CSV_SEP=${3:-';'}
OUTPUT_FILE_TMP=$(echo -n ${OUTPUT_FILE} | sed -r "s|(.*)csv|\1txt|")
UNTAGGED_RESOURCES=$(aws resource-explorer-2 search --query-string="region:us-east-1 -tag.key:${TAG_KEY}")


####################
# Helper Functions #
####################

# Helper function to estimate the tag from a given resource name or description
function resource_to_tag {
    name=$(echo -n ${1} | tr "[:upper:]" "[:lower:]")
    case ${name} in
        *"bbp_workflow"* | *"workflow"*) echo "bbp_workflow";;
        *"cell_svc"*) echo "cell_svc";;
        *"common"*) echo "common";;
        *"core_svc"*) echo "core_svc";;
        *"core_webapp"*) echo "core_webapp";;
        *"gitlab"*) echo "gitlab_runner";;
        *"hpc"*) echo "hpc";;
        *"keycloak"*) echo "keycloak";;
        *"kg_inference_api"*) echo "kg_inference_api";;
        *"marketplace"*) echo "marketplace-deployment";;
        *"me_model"*) echo "me_model_analysis";;
        *"nexus"*) echo "nexus";;
        *"pcluster"* | *"parallelcluster"* | *"fsx"*) echo "hpc:parallelcluster";;
        *"single_cell"*) echo "bluenaas_single_cell";;
        *"thumbnail_generation_api"*) echo "thumbnail_generation_api";;
        *"virtual_lab_manager"*) echo "virtual_lab_manager";;
        *"viz"*) echo "viz";;
        *"ml"* | *"machinelearning"*) echo "machinelearning";;  # Note: The order is on purpose
        *"bbp"*) echo "bbp:unknown";;
        *) echo "unknown";;
    esac
}

# Helper function to output each row of the CSV
function output {
    echo "${1}${CSV_SEP}${2}" | sed "s| |\\\\ |g"
}

# Helper function to support the retrieval of untagged EC2-related resources
function _get_untagged_ec2_base {
    # Retrieve the list of EC2 resources (e.g., ENI) and their metadata (e.g., security group, VPC, etc.)
    local arns=($(echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[] | select(.Arn | contains(\"${1}\")) | .Arn"))
    local ids=$(echo $(echo ${arns[@]} | tr ' ' '\n' | cut -d'/' -f2) | tr ' ' ',')
    local list=$(aws ec2 ${2} --filters Name=${3},Values=${ids})
    local list_size=$(echo ${list} | jq ".${4}[].${5}" | wc -l)

    # Try to guess the tag by selecting the security group and VPC IDs
    local resource_ids
    local resource_ids_alt
    for i in $(seq 0 1 $((${list_size}-1))); do
        local group_id=$(echo ${list} | jq -r ".${4}[$i].${6}" 2>/dev/null)
        local vpc_id=$(echo ${list} | jq -r ".${4}[$i].VpcId" 2>/dev/null)
        
        if [[ -z ${vpc_id} || ${vpc_id} == "null" ]]; then
            vpc_id=$(aws ec2 describe-security-groups --filters Name=group-id,Values=${group_id} | jq -r ".SecurityGroups[0].VpcId")
        fi

        resource_ids=(${resource_ids[@]} ${group_id:-"null"})
        resource_ids_alt=(${resource_ids_alt[@]} ${vpc_id:-"null"})
    done

    # Keep only the unique resource IDs and obtain the associated tags
    local resource_ids_all=$(echo ${resource_ids[@]} ${resource_ids_alt[@]} | tr ' ' '\n' | grep -v "null" | sort | uniq | tr '\n' ',' | sed -r "s|^(.*),$|\1|")
    local tag_list=$(aws ec2 describe-tags --filters Name=resource-id,Values=${resource_ids_all} Name=tag:${TAG_KEY},Values=*)

    # Given the list of tags from the properties of the previous step, associate them with each ARN
    for i in $(seq 0 1 $((${list_size}-1))); do
        local id=$(echo ${list} | jq -r ".${4}[$i].${5}")
        local arn=$(echo ${arns[@]} | tr ' ' '\n' | grep ${id})
        
        local tag=$(echo ${tag_list} | jq -r ".Tags[] | select(.ResourceId == \"${resource_ids[$i]}\") | .Value" 2>/dev/null)
        [[ -z ${tag} ]] && tag=$(echo ${tag_list} | jq -r ".Tags[] | select(.ResourceId == \"${resource_ids_alt[$i]}\") | .Value" 2>/dev/null)
        
        # If we reach this point and we still don't have a tag, let's try to guess it from the description
        [[ -z ${tag} ]] && tag=$(resource_to_tag $(echo ${list} | jq -r ".${4}[$i].Description"))

        output "${arn}" ${tag}
    done
}


#############################
# Untagged Lookup Functions #
#############################

# Function to get the list of untagged ENIs and their potential owner
function get_untagged_eni {
    _get_untagged_ec2_base "eni" \
                           "describe-network-interfaces" \
                           "network-interface-id" \
                           "NetworkInterfaces" \
                           "NetworkInterfaceId" \
                           "Groups[0].GroupId"
}

# Function to get the list of untagged Security Groups and their potential owner
function get_untagged_sg {
    _get_untagged_ec2_base "security-group/" \
                           "describe-security-groups" \
                           "group-id" \
                           "SecurityGroups" \
                           "GroupId" \
                           "GroupId"
}

# Function to get the list of untagged Security Group Rules and their potential owner
function get_untagged_sgr {
    _get_untagged_ec2_base "security-group-rule" \
                           "describe-security-group-rules" \
                           "security-group-rule-id" \
                           "SecurityGroupRules" \
                           "SecurityGroupRuleId" \
                           "GroupId"
}

# Function to get the list of untagged CloudWatch Alarms and their potential owner
function get_untagged_alarm {
    # Retrieve the list of CloudWatch Alarms and their metadata
    local alarm_names=($(echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[] | select(.Arn | contains(\":alarm:\")) | .Arn" | sed -r "s|.*:([^:]+)|\1|"))
    local alarm_list=$(aws cloudwatch describe-alarms --alarm-names ${alarm_names[@]})

    # Try to guess the tag by certain properties such as the ECS Cluster Name or the name of the alarm itself
    for i in $(seq 0 1 $(($(echo ${alarm_list} | jq ".MetricAlarms[].AlarmName" | wc -l)-1))); do
        local alarm_arn=$(echo ${alarm_list} | jq -r ".MetricAlarms[$i].AlarmArn")
        local resource_name=$(echo ${alarm_list} | jq -r ".MetricAlarms[$i].Dimensions[] | select(.Name == \"ClusterName\") | .Value" 2>/dev/null)
        [[ -z ${resource_name} ]] && resource_name=$(echo ${alarm_list} | jq -r ".MetricAlarms[$i].AlarmName")
        
        output "${alarm_arn}" "$(resource_to_tag ${resource_name})"
    done
}

# Function to get the list of untagged CloudWatch Log Groups and their potential owner
function get_untagged_loggroup {
    # As there is not much information to query for Log Groups, guess the tag by using the ARN
    for loggroup_arn in $(echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[] | select(.Arn | contains(\":log-group:\")) | .Arn"); do
        output "${loggroup_arn}" "$(resource_to_tag ${loggroup_arn})"
    done
}

# Function to get the list of untagged EC2 Key-Pairs and their potential owner
function get_untagged_keypair {
    # Retrieve the list of Key-Pairs and their metadata
    local keypair_arns=($(echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[] | select(.Arn | contains(\"key-pair\")) | .Arn"))
    local keypair_ids=$(echo $(echo ${keypair_arns[@]} | tr ' ' '\n' | cut -d'/' -f2) | tr ' ' ',')
    local keypair_list=$(aws ec2 describe-key-pairs --filters Name=key-pair-id,Values=${keypair_ids})

    # Try to guess the tag by the name of the resource
    for i in $(seq 0 1 $(($(echo ${keypair_list} | jq ".KeyPairs[].KeyPairId" | wc -l)-1))); do
        local keypair_arn=$(echo ${keypair_arns[@]} | tr ' ' '\n' | grep $(echo ${keypair_list} | jq -r ".KeyPairs[$i].KeyPairId"))
        local keypair_name=$(echo ${keypair_list} | jq -r ".KeyPairs[$i].KeyName")

        output "${keypair_arn}" "$(resource_to_tag ${keypair_name})"
    done
}

# Function to get the list of untagged KMS Keys and their potential owner
function get_untagged_kms_key {
    # Retrieve the ARNs of the untagged KMS Keys
    local kms_key_arns=($(echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[] | select(.Arn | contains(\":key/\")) | .Arn"))

    # Try to guess the tag by the ARN of the resource
    for kms_key_arn in ${kms_key_arns[@]}; do
        # aws kms describe-key --key-id ${kms_key} << Description may be useful in the future
        output "${kms_key_arn}" "$(resource_to_tag ${kms_key_arn})"
    done
}

# Function to get the list of untagged ECS Container Instances and their potential owner
function get_untagged_ecs_ci {
    # Retrieve the ARNs of the untagged ECS Container Instances
    local ecs_ci_arns=($(echo ${UNTAGGED_RESOURCES} | jq -r ".Resources[] | select(.Arn | contains(\"container-instance\")) | .Arn"))

    # Try to guess the tag by the name of the resource
    for ecs_ci_arn in ${ecs_ci_arns[@]}; do
        # aws ecs describe-container-instances --cluster single_cell --container-instances 0318bb9... << Description may be useful in the future
        output "${ecs_ci_arn}" "$(resource_to_tag ${ecs_ci_arn})"
    done
}


######################
# Main Functionality #
######################

# Generate the output CSV with all of the deducted tags
echo "ARN;Owner"              \
     $(get_untagged_eni)      \
     $(get_untagged_sg)       \
     $(get_untagged_sgr)      \
     $(get_untagged_alarm)    \
     $(get_untagged_loggroup) \
     $(get_untagged_keypair)  \
     $(get_untagged_kms_key)  \
     $(get_untagged_ecs_ci)   |
    tr ' ' '\n' | { sed -u 1q; sort -t${CSV_SEP} -k2; } > ${OUTPUT_FILE}

# Pretty-print the result on-screen
cat ${OUTPUT_FILE} | tr ${CSV_SEP} '\t' | tablign > ${OUTPUT_FILE_TMP}
sep_length=$(cat ${OUTPUT_FILE_TMP} | awk '{ print length }' | sort -nr | head -n1 | cut -d' ' -f1)
sed -i "2i$(printf -- '-%0.s' $(seq 1 1 ${sep_length}))" ${OUTPUT_FILE_TMP}

cat ${OUTPUT_FILE_TMP}

echo -e "\n\nFound $(($(sed 1d ${OUTPUT_FILE} | wc -l))) resources untagged.\nSee list above or" \
        "download the '${OUTPUT_FILE}' artifact for further information."
