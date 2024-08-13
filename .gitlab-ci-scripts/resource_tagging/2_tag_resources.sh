#!/bin/bash

source "$(dirname ${0})/common.sh"

INPUT_FILE=${1:-"untagged_resources.csv"}
OUTPUT_FILE=${2:-"modified_resources.csv"}


####################
# Helper Functions #
####################

# Helper function to support the update of untagged resources
function _update_untagged_base {
    if [[ -z $(declare -fF _tag_resource_fn) ]]; then
        >&2 echo "[ERROR] '_tag_resource_fn' is undeclared for '${1}:${2}'."
        exit 134  # ENOSYS
    fi

    local arns=($(grep -P ".*:${1}:.*:${2}${3:-":"}.*" ${INPUT_FILE} | cut -d${CSV_SEP} -f1 | replace_spaces))
    local tags=($(grep -P ".*:${1}:.*:${2}${3:-":"}.*" ${INPUT_FILE} | cut -d${CSV_SEP} -f2))

    for i in $(seq 0 1 $((${#arns[@]}-1))); do
        local arn=$(restore_spaces "${arns[$i]}")
        local tag=${tags[$i]}

        # If the resource does not contain a valid tag, skip the entry
        [[ ${tag} == ${TAG_UNKNOWN} || ${tag} == ${TAG_IGNORED} ]] && continue

        local tags_short="Key=${TAG_KEY},Value=${tag} Key=${AUTOTAG_KEY},Value=${TIMESTAMP}"
        local tags_json="[{\"Key\":\"${TAG_KEY}\",\"Value\":\"${tag}\"},{\"Key\":\"${AUTOTAG_KEY}\",\"Value\":\"${TIMESTAMP}\"}]"

        # Call the specific function to tag the resource and output the entry
        _tag_resource_fn && output "${arn}" "${tag}"
    done

    unset _tag_resource_fn
}


############################
# Tag Definition Functions #
############################

# Function to update the untagged CloudWatch Alarms with their owner
function update_untagged_alarm {
    function _tag_resource_fn {
        aws cloudwatch tag-resource --resource-arn "${arn}" --tags "${tags_json}"
        return $?
    }

    _update_untagged_base "cloudwatch" "alarm"
}

# Function to update the untagged VPC Endpoint ENIs with their owner
function update_untagged_eni_vpce {
    function _tag_resource_fn {
        local eni_id=$(echo -n ${arn} | cut -d'/' -f2)
        local eni_type=$(aws ec2 describe-network-interfaces --network-interface-ids "${eni_id}" | \
                         jq -r ".NetworkInterfaces[].InterfaceType")
        
        # Ignore entry if the ENI does not belong to a VPC Endpoint
        [[ ${eni_type} != "vpc_endpoint" ]] && return 22  # EINVAL
        
        aws ec2 create-tags --resources "${eni_id}" --tags "${tags_json}"

        return $?
    }

    _update_untagged_base "ec2" "network-interface" "/"
}


######################
# Main Functionality #
######################

# Ensure that the input file exists, or return otherwise
if [[ ! -f "${INPUT_FILE}" ]]; then
    echo "[INFO] '${INPUT_FILE}' not found, skipping the tag modification process."
    exit 0
fi

# Append the output from each 'update_untagged_*' function into a temporary file
run_script_fns "tag update" "update_untagged_"

# Generate the output CSV with all of the modified resources
output_result_csv ${OUTPUT_FILE}

# Finally, provide a summary of the results obtained
num_resources_modified=$(sed 1d ${OUTPUT_FILE} 2>/dev/null | wc -l)
echo -e "\n\n\nModified ${num_resources_modified} resources with two new tags '${TAG_KEY}' and '${AUTOTAG_KEY}'.\nSee" \
        "next CI jobs for further information and downloadable artifacts."
