# Startup script for runner VM.

# Create working directory.
mkdir /dss
cd /dss

# Install dependencies.
apt update && apt install -y \
    build-essential \
    git \
    gnupg \
    libpq-dev \
    postgresql-client \
    software-properties-common
# https://developer.hashicorp.com/terraform/install
# https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli
wget -O- https://apt.releases.hashicorp.com/gpg |
    gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
    tee /etc/apt/sources.list.d/hashicorp.list
apt update && apt install -y terraform
# https://cloud.google.com/sql/docs/mysql/sql-proxy#linux-64-bit
curl -o cloud-sql-proxy "\
https://storage.googleapis.com/cloud-sql-connectors/\
cloud-sql-proxy/v2.8.1/cloud-sql-proxy.linux.amd64"
chmod +x cloud-sql-proxy
mv cloud-sql-proxy /usr/bin/cloud-sql-proxy
# https://www.rust-lang.org/tools/install
# https://github.com/rust-lang-deprecated/rustup.sh/issues/83
# https://stackoverflow.com/a/52445962
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -sSf | sh -s -- -y
export PATH="/root/.cargo/bin:$PATH"
# https://diesel.rs/guides/getting-started
cargo install diesel_cli --no-default-features --features postgres

# Get service account key.
SERVICE_ACCOUNT_NAME=terraform@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts keys create $CREDENTIALS_FILE \
    --iam-account $SERVICE_ACCOUNT_NAME

# Initialize Terraform project.
git clone \
    https://github.com/econia-labs/econia.git \
    --branch ECO-1018 \
    --recurse-submodules
cp -R econia/src/terraform/dss-ci-cd/dss/* .
cp -R econia/src/rust/dbv2/migrations migrations
echo "\
project = \"$PROJECT_ID\"
credentials_file = \"$CREDENTIALS_FILE\"
db_root_password = \"$DB_ROOT_PASSWORD\"
aptos_network = \"$APTOS_NETWORK\"
econia_address = \"$ECONIA_ADDRESS\"
starting_version = \"$STARTING_VERSION\"
grpc_data_service_address = \"$GRPC_DATA_SERVICE_ADDRESS\"
grpc_auth_token = \"$GRPC_AUTH_TOKEN\"" >terraform.tfvars
terraform fmt
terraform init
