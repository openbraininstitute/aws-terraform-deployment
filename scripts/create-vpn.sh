#!/bin/bash
set -eu

#########################
# Configuration Section #
#########################

OUTPUT_DIR="${OUTPUT_DIR:-./out}"

# Certificate file names
ROOT_CA_KEY="${OUTPUT_DIR}/ca.key"
ROOT_CA_CERT="${OUTPUT_DIR}/ca.crt"
SERVER_KEY="${OUTPUT_DIR}/server.key"
SERVER_CSR="${OUTPUT_DIR}/server.csr"
SERVER_CERT="${OUTPUT_DIR}/server.crt"
CLIENT_KEY="${OUTPUT_DIR}/client.key"
CLIENT_CSR="${OUTPUT_DIR}/client.csr"
CLIENT_CERT="${OUTPUT_DIR}/client.crt"

# Subjects for the certificates (modify as needed)
ROOT_CA_SUBJECT="${ROOT_CA_SUBJECT:-/CN=sandboxnse Root CA}"
SERVER_SUBJECT="${SERVER_SUBJECT:-/CN=clientvpn.us-east-1.amazonaws.com}"
CLIENT_SUBJECT="${CLIENT_SUBJECT:-/CN=vpnclient}"

# OpenVPN Client Configuration file
CLIENT_CONFIG="${CLIENT_CONFIG:-client-config.ovpn}"
CLIENT_CONFIG="${OUTPUT_DIR}/${CLIENT_CONFIG}"

# AWS settings (update these)
CLIENT_CIDR="${CLIENT_CIDR:-10.1.0.0/22}"  # IP pool for VPN clients (should not overlap with your VPC)
VPC_CIDR="${VPC_CIDR:-10.0.0.0/16}"        # Your VPC CIDR for authorization
REGION="${REGION:-us-east-1}"              # AWS region
VPC_ID="${VPC_ID:-vpc-0045fb7d66fe70880}"  # Replace with your VPC ID
SUBNET_ID="${SUBNET_ID:-subnet-0b9384ed60b077713}"  # Replace with a subnet ID in your VPC (must be associated with a target network)

TAG_KEY="${TAG_KEY:-SBO_Billing}"
TAG_VALUE="${TAG_VALUE:-entitycore}"

export AWS_PROFILE="${AWS_PROFILE:-sandbox-nse-admin}"

function prepare_output_dir {
    echo "Creating output directory ${OUTPUT_DIR} if it doesn't exist"
    mkdir -p "${OUTPUT_DIR}"
}

function login_to_aws {
    if ! aws sts get-caller-identity --query "Account" --output text >/dev/null 2>&1; then
        echo "AWS SSO session expired or not found. Logging in..."
        aws sso login
    else
        echo "AWS SSO session is active for AWS_PROFILE=${AWS_PROFILE}."
    fi
}

function generate_certificates {
    echo "Generating Root CA..."
    openssl genrsa -out ${ROOT_CA_KEY} 2048
    openssl req -x509 -new -nodes -key ${ROOT_CA_KEY} -days 1024 -out ${ROOT_CA_CERT} -subj "${ROOT_CA_SUBJECT}" \
      -addext "keyUsage = critical, keyCertSign, cRLSign"

    echo "Generating Server Certificate..."
    openssl genrsa -out ${SERVER_KEY} 2048
    openssl req -new -key ${SERVER_KEY} -out ${SERVER_CSR} -subj "${SERVER_SUBJECT}"
    openssl x509 -req -in ${SERVER_CSR} -CA ${ROOT_CA_CERT} -CAkey ${ROOT_CA_KEY} -CAcreateserial -out ${SERVER_CERT} -days 500 \
      -extfile <(printf "[v3_ext]\nextendedKeyUsage=serverAuth\nkeyUsage=digitalSignature,keyEncipherment") -extensions v3_ext

    echo "Generating Client Certificate..."
    openssl genrsa -out ${CLIENT_KEY} 2048
    openssl req -new -key ${CLIENT_KEY} -out ${CLIENT_CSR} -subj "${CLIENT_SUBJECT}"
    openssl x509 -req -in ${CLIENT_CSR} -CA ${ROOT_CA_CERT} -CAkey ${ROOT_CA_KEY} -CAcreateserial -out ${CLIENT_CERT} -days 500 \
      -extfile <(printf "[v3_ext]\nextendedKeyUsage=clientAuth\nkeyUsage=digitalSignature,keyEncipherment") -extensions v3_ext
}

function import_certificates {
    echo "Importing Server Certificate into ACM..."
    SERVER_CERT_ARN=$(aws acm import-certificate \
      --certificate fileb://${SERVER_CERT} \
      --private-key fileb://${SERVER_KEY} \
      --certificate-chain fileb://${ROOT_CA_CERT} \
      --region ${REGION} \
      --tags Key=$TAG_KEY,Value=$TAG_VALUE \
      --output text --query 'CertificateArn')
    echo "SERVER_CERT_ARN=${SERVER_CERT_ARN}"

    echo "Importing Root CA Certificate into ACM..."
    ROOT_CERT_ARN=$(aws acm import-certificate \
      --certificate fileb://${ROOT_CA_CERT} \
      --private-key fileb://${ROOT_CA_KEY} \
      --region ${REGION} \
      --tags Key=$TAG_KEY,Value=$TAG_VALUE \
      --output text --query 'CertificateArn')
    echo "ROOT_CERT_ARN=${ROOT_CERT_ARN}"
}

function create_client_vpn_endpoint {
    echo "Creating AWS Client VPN Endpoint..."
    OUTPUT=$(aws ec2 create-client-vpn-endpoint \
      --client-cidr-block ${CLIENT_CIDR} \
      --server-certificate-arn ${SERVER_CERT_ARN} \
      --authentication-options Type=certificate-authentication,MutualAuthentication="{ClientRootCertificateChainArn=${ROOT_CERT_ARN}}" \
      --connection-log-options Enabled=false \
      --region ${REGION} \
      --tag-specifications "ResourceType=client-vpn-endpoint,Tags=[{Key=${TAG_KEY},Value=${TAG_VALUE}}]" \
      --split-tunnel \
      --output json)

    # Extract the Client VPN Endpoint ID using jq
    ENDPOINT_ID=$(echo ${OUTPUT} | jq -r '.ClientVpnEndpointId')
    echo "ENDPOINT_ID=${ENDPOINT_ID}"
}

function associate_target_network {
    echo "Associating target network (subnet ${SUBNET_ID})..."
    OUTPUT=$(aws ec2 associate-client-vpn-target-network \
      --client-vpn-endpoint-id ${ENDPOINT_ID} \
      --subnet-id ${SUBNET_ID} \
      --region ${REGION} \
      --output json)

    ASSOCIATION_ID=$(echo ${OUTPUT} | jq -r '.AssociationId')
    echo "ASSOCIATION_ID=${ASSOCIATION_ID}"

    echo "Adding authorization rule to allow access to ${VPC_CIDR}..."
    aws ec2 authorize-client-vpn-ingress \
      --client-vpn-endpoint-id ${ENDPOINT_ID} \
      --target-network-cidr ${VPC_CIDR} \
      --authorize-all-groups \
      --description "Allow access to VPC" \
      --region ${REGION}

    aws ec2 describe-client-vpn-target-networks --client-vpn-endpoint-id ${ENDPOINT_ID}
    echo "AWS Client VPN with mutual authentication setup is complete, but the association may require some minutes."
}

function export_openvpn_config {
    echo "Exporting OpenVPN client configuration to: ${CLIENT_CONFIG}"

    aws ec2 export-client-vpn-client-configuration \
      --client-vpn-endpoint-id ${ENDPOINT_ID} \
      --output text > ${CLIENT_CONFIG}
    echo -e "\n<cert>\n$(cat ${CLIENT_CERT})\n</cert>\n<key>\n$(cat ${CLIENT_KEY})\n</key>" >> ${CLIENT_CONFIG}
}

function destroy_all {
    echo "Ensuring that the AWS session is still active"
    login_to_aws

    echo "Deleting the AWS Client VPN Endpoint"
    aws ec2 disassociate-client-vpn-target-network \
      --client-vpn-endpoint-id ${ENDPOINT_ID} \
      --association-id ${ASSOCIATION_ID}
    aws ec2 delete-client-vpn-endpoint --client-vpn-endpoint-id ${ENDPOINT_ID}

    echo "Deleting the imported certificates"
    aws acm delete-certificate --certificate-arn ${SERVER_CERT_ARN}
    aws acm delete-certificate --certificate-arn ${ROOT_CERT_ARN}
}

function print_recap {
    echo "### AWS RESOURCES RECAP"
    echo "SERVER_CERT_ARN=${SERVER_CERT_ARN}"
    echo "ROOT_CERT_ARN=${ROOT_CERT_ARN}"
    echo "ENDPOINT_ID=${ENDPOINT_ID}"
    echo "ASSOCIATION_ID=${ASSOCIATION_ID}"
}

function confirm_and_execute {
    local func_name="$1"
    local prompt="${2:-Run $1? (y/n):}"
    local skip_message="${3:-Skipping $func_name.}"
    local response
    while true; do
        read -rp "$prompt " response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
        case "$response" in
            y|yes)
                "$func_name"
                return 0
                ;;
            n|no)
                echo "$skip_message"
                return 1
                ;;
            *)
                echo "Invalid input. Please enter y or n."
                ;;
        esac
    done
}


DISCLAIMER=("
##################################################################################
DISCLAIMER
##################################################################################
This script is intended as a temporary solution for directly connecting to
services in a sandbox environment, not as a long-term solution. Be sure to
destroy any created resources to avoid unnecessary charges for unused services.
##################################################################################
")

echo "$DISCLAIMER"
confirm_and_execute echo "Proceed? (y/n)" "Exiting" || exit 1
prepare_output_dir
login_to_aws
generate_certificates
import_certificates
create_client_vpn_endpoint
associate_target_network
export_openvpn_config
print_recap
confirm_and_execute destroy_all
echo "Script completed successfully"
