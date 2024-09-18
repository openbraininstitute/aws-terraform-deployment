#!/bin/bash

####################
# Global Variables #
####################

TAG_KEY="SBO_Billing"
AUTOTAG_KEY="SBO_Billing:auto-tag"
TAG_UNKNOWN="unknown"
TAG_IGNORED="ignored/error"
RESOURCE_VALID_THRESHOLD=$((48 * 3600))  # 48 hours (in seconds)
COMMENT_UPDATE_THRESHOLD=$(( 8 * 3600))  #  8 hours (in seconds)
ARN_UNKNOWN_SUFFIX="##__DELETED__##"
CSV_SEP=','
CSV_HEADER="ARN${CSV_SEP}Owner"
TIMESTAMP=$(date +%s)
SPACE_KEYWORD="##__0x20_${TIMESTAMP}__##"
OUTPUT_FILE_TMP=/tmp/resource_tagging.${TIMESTAMP}.out


####################
# Helper Functions #
####################

# Helper function to estimate the tag from a given resource name or description
function resource_to_tag {
    name=$(echo -n ${1} | tr "[:upper:]" "[:lower:]")
    case ${name} in
        *"bbp_workflow"* | *"workflow"*) echo "bbp_workflow";;
        *"cell_svc"*) echo "cell_svc";;
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
        *"bluenaas"* | *"single_cell"*) echo "bluenaas";;
        *"thumbnail_generation_api"*) echo "thumbnail_generation_api";;
        *"virtual_lab_manager"*) echo "virtual_lab_manager";;
        *"viz"*) echo "viz";;
        *"ml"* | *"machinelearning"*) echo "machinelearning";;  # Note: The order is on purpose
        *"common"* | *"default"* | *"sbo"*) echo "common";;
        *"bbp"*) echo "bbp:unknown";;
        *) echo ${TAG_UNKNOWN};;
    esac
}

# Helper function to output each row of the CSV
function output {
    echo "${1}${CSV_SEP}${2}"
}

# Helper function to output the result CSV ordered by owner
function output_result_csv {
    if [[ -s ${OUTPUT_FILE_TMP} ]]; then
        echo ${CSV_HEADER} > ${1}
        sort -t${CSV_SEP} -k2 ${OUTPUT_FILE_TMP} >> ${1}
        rm -f ${OUTPUT_FILE_TMP}
    fi
}

# Helper function to replace spaces with a keyword
function replace_spaces {
    if [[ ${#} -gt 0 ]]; then
        echo "${@}" | sed "s| |${SPACE_KEYWORD}|g"
    else
        while read input; do
            echo "${input}" | sed "s| |${SPACE_KEYWORD}|g"
        done
    fi
}

# Helper function to restore spaces replaced with a keyword
function restore_spaces {
    if [[ ${#} -gt 0 ]]; then
        echo "${@}" | sed "s|${SPACE_KEYWORD}| |g"
    else
        while read input; do
            echo "${input}" | sed "s|${SPACE_KEYWORD}| |g"
        done
    fi
}

# Helper function to calculate the elapsed time (in seconds) since a given date
function get_elapsed {
    echo -n $(($(date +%s) - $(date -d "${1}" +%s)))
}

# Helper function to run the specific functions from each script
function run_script_fns {
    echo "Runnning ${1} functions:"
    fn_list=($(grep "function ${2}" ${0} | grep -v "grep" | sed -r "s|^function ([^ ]+).*$|\1|" | sort))
    for fn in ${fn_list[@]}; do
        fn_description="$(sed -n $(($(grep -n "function ${fn}" ${0} | cut -d':' -f1 | head -n 1)-1))p ${0})"
        echo "  - '${fn}()'  ${fn_description}"
        eval ${fn} >> ${OUTPUT_FILE_TMP}
    done
}
