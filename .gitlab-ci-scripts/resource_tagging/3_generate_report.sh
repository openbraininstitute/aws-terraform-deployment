#!/bin/bash

source "$(dirname ${0})/common.sh"

INPUT_FILE_U=${1:-"untagged_resources.csv"}
INPUT_FILE_I=${2:-"ignored_resources.csv"}
INPUT_FILE_M=${3:-"modified_resources.csv"}
OUTPUT_FILE_T=${4:-"tagged_resources.csv"}
TICKET_ID="BBPP154-279"
COMMENT_ID="251281"
AUTH_TOKEN="$(aws secretsmanager get-secret-value --secret-id "obp_bot_token" | jq -r ".SecretString")"
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

# Calculate the number of resources for each category and generate the report
num_resources_modified=$(sed 1d ${INPUT_FILE_M} 2>/dev/null | wc -l)
num_resources_ignored=$(sed 1d ${INPUT_FILE_I}  2>/dev/null | wc -l)
num_resources_untagged=$(sed 1d ${INPUT_FILE_U} 2>/dev/null | wc -l)
num_resources_tagged=$(sed 1d ${OUTPUT_FILE_T}  2>/dev/null | wc -l)
report="$(
    CI_JOB_STARTED_AT="$(TZ=UTC-2 date -d "${CI_JOB_STARTED_AT}" "+%Y-%m-%dT%H:%M:%S")"  # Convert to CET
    
    if [[ ${num_resources_untagged} -eq 0 ]]; then
        color="009900"  # Green text color
        icon="(/)"      # Jira's success icon
    else
        color="ff0000"  # Red text color
        icon="(x)"      # Jira's error icon
    fi
    
    echo -n "${icon} {color:#${color}}*Current overall status of '{{${TAG_KEY}}}' tagging* [Updated: ${CI_JOB_STARTED_AT}]:{color}\n\n"
    [[ ${num_resources_modified} -gt 0 ]] && echo -n " - ${num_resources_modified} resources have been modified and manually tagged with '{{${TAG_KEY}}}' and '{{${AUTOTAG_KEY}}}'.\n"
    [[ ${num_resources_ignored}  -gt 0 ]] && echo -n " - ${num_resources_ignored} could not be verified or are purposely ignored (e.g., untaggeable resources managed by AWS).\n"
    [[ ${num_resources_tagged}   -gt 0 ]] && echo -n " - ${num_resources_tagged} resources are properly tagged with '{{${TAG_KEY}}}' and accounted for.\n"

    if [[ ${num_resources_untagged} -gt 0 ]]; then
        echo -n " - ${num_resources_untagged} resources have been identified as '{{${TAG_KEY}}}' untagged:\n" \
                "{code:bash}\n$(sed 1d ${INPUT_FILE_U} 2>/dev/null | cut -d${CSV_SEP} -f2 | uniq -c | tr '\n' '#' | sed 's|#|\\n|g'){code}\n" \
                "\n*Please, it is advisable for every team to revise the latest CSV output for the untagged resources:*" \
                "\nhttps://bbpgitlab.epfl.ch/cs/cloud/aws/deployment/-/jobs/${CI_JOB_ID}/artifacts/file/untagged_resources.csv"
    else
        echo -n "\n\nNo immediate action is required by any team (i.e., all of the resources are properly identified)."
    fi
)"

# Update the ticket with the latest information, but only if the last update is older than a threshold
ticket_url="https://bbpteam.epfl.ch/project/issues/rest/api/2/issue/${TICKET_ID}/comment/${COMMENT_ID}"
last_update=$(curl -s -u obp_bot:${AUTH_TOKEN} -X GET ${ticket_url} | jq -r ".updated")
if [[ $(get_elapsed "${last_update}") -ge ${COMMENT_UPDATE_THRESHOLD} ]]; then
    curl -s -u obp_bot:${AUTH_TOKEN} -X PUT --data "{\"body\": \"${report}\"}" \
                                     -H "Content-Type: application/json" ${ticket_url} 1>/dev/null
fi

# Finally, print the summary without the Jira format
echo -e "${report}" | tr -d '*' | sed -r "s|'\{\{([^\}]+)\}\}'|'\1'|g" | sed -r "s|\{co[^\}]*}||g" | sed -r "s|^\([/x]\) ([^ ].*$)|\1|"
