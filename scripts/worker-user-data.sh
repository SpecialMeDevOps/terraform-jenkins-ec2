#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="/var/log/jenkins-worker-bootstrap.log"
DOWNLOAD_DIR="/var/lib/jenkins-lab/downloads"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'status=$?; echo "Bootstrap failed (exit ${status}); see ${LOG_FILE}."; exit "$status"' ERR
export DEBIAN_FRONTEND=noninteractive
install -d -m 0755 "$DOWNLOAD_DIR" /etc/apt/keyrings

install_packages_if_missing() {
  local missing=()
  local package
  for package in "$@"; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q 'install ok installed'; then
      missing+=("$package")
    fi
  done
  if ((${#missing[@]} > 0)); then
    apt-get install -y "${missing[@]}"
  fi
}

echo "== Checking outbound networking =="
ip -brief address
ip route
curl --fail --silent --show-error --connect-timeout 10 https://archive.ubuntu.com/ubuntu/ >/dev/null

echo "== Installing base packages =="
apt-get update -y
install_packages_if_missing ca-certificates curl fontconfig git gnupg unzip openjdk-21-jre

echo "== Installing Docker Engine and Compose plugin =="
if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
  apt-get update
  install_packages_if_missing docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker
usermod -aG docker ubuntu

echo "== Installing kubectl stable release =="
if ! command -v kubectl >/dev/null 2>&1; then
  kubectl_version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o "$DOWNLOAD_DIR/kubectl" "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 "$DOWNLOAD_DIR/kubectl" /usr/local/bin/kubectl
fi

echo "== Installing Helm from the official repository =="
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor --yes -o /etc/apt/keyrings/helm.gpg
  chmod a+r /etc/apt/keyrings/helm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" > /etc/apt/sources.list.d/helm-stable-debian.list
  apt-get update
  install_packages_if_missing helm
fi

echo "== Installing AWS CLI v2 from the official installer =="
if ! command -v aws >/dev/null 2>&1 || ! aws --version 2>&1 | grep -q 'aws-cli/2\.'; then
  curl -fsSL -o "$DOWNLOAD_DIR/awscliv2.zip" https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
  rm -rf "$DOWNLOAD_DIR/aws"
  unzip -q "$DOWNLOAD_DIR/awscliv2.zip" -d "$DOWNLOAD_DIR"
  "$DOWNLOAD_DIR/aws/install" --update
fi

echo "== Installing Terraform from the HashiCorp repository =="
if ! command -v terraform >/dev/null 2>&1; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/hashicorp.gpg
  chmod a+r /etc/apt/keyrings/hashicorp.gpg
  echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" > /etc/apt/sources.list.d/hashicorp.list
  apt-get update
  install_packages_if_missing terraform
fi

echo "== Verification summary =="
git --version
java -version
docker --version
docker compose version
kubectl version --client
helm version
aws --version
terraform version
echo "Bootstrap complete. Jenkins is intentionally not installed on this worker."
echo "Docker group changes apply to new ubuntu sessions."
