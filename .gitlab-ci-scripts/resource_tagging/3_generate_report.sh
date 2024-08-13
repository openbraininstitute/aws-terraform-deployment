#!/bin/bash

source "$(dirname ${0})/common.sh"

INPUT_FILE_U=${1:-"untagged_resources.csv"}
INPUT_FILE_M=${2:-"modified_resources.csv"}
OUTPUT_FILE_T=${3:-"tagged_resources.csv"}
TAGGED_RESOURCES=$(aws resource-explorer-2 search --query-string="region:us-east-1 tag.key:${TAG_KEY}")


######################
# Main Functionality #
######################

# Generate the output CSV with all of the untagged resources minus the modified ones, if any
if [[ -f "${INPUT_FILE_U}" && -f "${INPUT_FILE_M}" ]]; then
    sed 1d -i ${INPUT_FILE_M}  # Remove the CSV header for 'grep'
    grep -v -x -f ${INPUT_FILE_M} ${INPUT_FILE_U} > ${OUTPUT_FILE_TMP}
    mv ${OUTPUT_FILE_TMP} ${INPUT_FILE_U}
    sed "1i ${CSV_HEADER}" -i ${INPUT_FILE_M}  # Restore CSV header
fi

# Generate the output CSV with all of the tagged resources
tagged_arns=($(echo ${TAGGED_RESOURCES} | jq -r ".Resources[].Arn" | replace_spaces))
for tagged_arn in ${tagged_arns[@]}; do
    arn=$(restore_spaces "${tagged_arn}")
    tag=$(echo ${TAGGED_RESOURCES} | jq -r ".Resources[] | select(.Arn == \"${arn}\") | \
                                            .Properties[].Data[] | select(.Key == \"${TAG_KEY}\") | .Value")

    output "${arn}" "${tag}" >> ${OUTPUT_FILE_TMP}
done

output_result_csv ${OUTPUT_FILE_T}

# Finally, provide a summary of the results obtained
num_resources_modified=$(sed 1d ${INPUT_FILE_M} 2>/dev/null | wc -l)
num_resources_untagged=$(sed 1d ${INPUT_FILE_U} 2>/dev/null | grep -v "${TAG_IGNORED}" | wc -l)
num_resources_ignored=$(grep "${TAG_IGNORED}" ${INPUT_FILE_U}  2>/dev/null | wc -l)
num_resources_tagged=$(sed 1d ${OUTPUT_FILE_T}  2>/dev/null | wc -l)
echo -e "After running the tag verification scripts, here is a summary of the results:\n\n" \
        " - ${num_resources_modified} resources have been modified and manually tagged with '${TAG_KEY}' and '${AUTOTAG_KEY}'.\n" \
        " - ${num_resources_untagged} resources have been identified as untagged, among which ${num_resources_ignored} cannot be verified.\n" \
        " - ${num_resources_tagged} resources are properly tagged and accounted for.\n" \
        "\nSee output CSV artifacts from the CI job for further information and specific details."