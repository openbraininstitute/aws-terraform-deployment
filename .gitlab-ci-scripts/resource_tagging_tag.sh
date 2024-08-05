#!/bin/bash

INPUT_FILE=${1:-"untagged_resources.tmp"}
OUTPUT_FILE_M=${2:-"modified_resources.csv"}
OUTPUT_FILE_U=${3:-"untagged_resources.csv"}
OUTPUT_FILE_T=${4:-"tagged_resources.csv"}

OUTPUT_FILE_TMP=/tmp/$(basename ${INPUT_FILE})_$(date +%s)
TAG_KEY="SBO_Billing"
AUTOTAG_KEY="SBO_Billing:auto-tag"
AUTOTAG_TS="$(date +%s)"
TAG_UNKNOWN="unknown"
TAG_IGNORED="ignored/error"
CSV_SEP=','


####################
# Helper Functions #
####################

# Helper function to output each row of the CSV
function output {
    echo "${1}${CSV_SEP}${2}" | sed "s| |\\\\ |g"
}


############################
# Tag Definition Functions #
############################

# Function to update the untagged CloudWatch Alarms with their owner
function update_untagged_alarm {
    local arns=($(grep -P ".*:cloudwatch:.*:alarm:.*" ${INPUT_FILE} | cut -d${CSV_SEP} -f1))
    local tags=($(grep -P ".*:cloudwatch:.*:alarm:.*" ${INPUT_FILE} | cut -d${CSV_SEP} -f2))

    for i in $(seq 0 1 $((${#arns[@]}-1))); do
        local arn=${arns[$i]}
        local tag=${tags[$i]}

        # If the resource does not contain a valid tag, skip the entry
        [[ ${tag} == ${TAG_UNKNOWN} || ${tag} == ${TAG_IGNORED} ]] && continue

        aws cloudwatch tag-resource --resource-arn "${arn}" --tags "[{\"Key\":\"${TAG_KEY}\",\"Value\":\"${tag}\"}, \
                                                                     {\"Key\":\"${AUTOTAG_KEY}\",\"Value\":\"${AUTOTAG_TS}\"}]"
        
        output "${arn}" "${tag}"
    done
}



######################
# Main Functionality #
######################

# Append the output from each 'update_untagged_*' function into a temporary file
echo "Runnning tag update functions:"
update_untagged_fn_list=($(grep "function update_untagged_" ${0} | grep -v "grep" | sed -r "s|^function ([^ ]+).*$|\1|" | sort))
for update_untagged_fn in ${update_untagged_fn_list[@]}; do
    fn_description="$(sed -n $(($(grep -n "function ${update_untagged_fn}" ${0} | cut -d':' -f1 | head -n 1)-1))p ${0})"
    echo "  - '${update_untagged_fn}()'  ${fn_description}"
    eval ${update_untagged_fn} >> ${OUTPUT_FILE_TMP}
done

# Generate the output CSV with all of the modified resources
head -n1 ${INPUT_FILE} > ${OUTPUT_FILE_M}
sort -t${CSV_SEP} -k2 ${OUTPUT_FILE_TMP} >> ${OUTPUT_FILE_M}

# Generate the output CSV with all of the untagged resources
grep -v -x -f ${OUTPUT_FILE_TMP} ${INPUT_FILE} > ${OUTPUT_FILE_U}
rm -f ${OUTPUT_FILE_TMP}

# Generate the output CSV with all of the tagged resources
TAGGED_RESOURCES=$(aws resource-explorer-2 search --query-string="region:us-east-1 tag.key:${TAG_KEY}")
tagged_arns=($(echo ${TAGGED_RESOURCES} | jq -r ".Resources[].Arn" | sed "s| |#|g"))  # Replace spaces in some ARNs
for tagged_arn in ${tagged_arns[@]}; do
    arn="$(echo ${tagged_arn} | sed "s|#| |g")"  # Restore spaces in some ARNs
    tag=$(echo ${TAGGED_RESOURCES} | jq -r ".Resources[] | select(.Arn == \"${arn}\") | \
                                            .Properties[].Data[] | select(.Key == \"${TAG_KEY}\") | .Value")

    output "${arn}" "${tag}" >> ${OUTPUT_FILE_TMP}
done

head -n1 ${INPUT_FILE} > ${OUTPUT_FILE_T}
sort -t${CSV_SEP} -k2 ${OUTPUT_FILE_TMP} >> ${OUTPUT_FILE_T}
rm -f ${OUTPUT_FILE_TMP}

# Finally, provide a summary of the results obtained
num_resources_modified=$(sed 1d ${OUTPUT_FILE_M} | wc -l)
num_resources_untagged=$(sed 1d ${OUTPUT_FILE_U} | grep -v "${TAG_IGNORED}" | wc -l)
num_resources_ignored=$(grep "${TAG_IGNORED}" ${OUTPUT_FILE_U} | wc -l)
num_resources_tagged=$(sed 1d ${OUTPUT_FILE_T} | wc -l)
echo -e "\n\n\nAfter running the tag verification scripts, here is a summary of the results:\n\n" \
        " - ${num_resources_modified} resources have been modified and manually tagged with '${TAG_KEY}' and '${AUTOTAG_KEY}'.\n" \
        " - ${num_resources_untagged} resources have been identified as untagged, among which ${num_resources_ignored} cannot be verified.\n" \
        " - ${num_resources_tagged} resources are properly tagged and accounted for.\n" \
        "\nSee artifacts '${OUTPUT_FILE_M}', '${OUTPUT_FILE_U}' and '${OUTPUT_FILE_T}' for further information."
