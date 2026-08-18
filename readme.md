---
assume_role_role_arn: "arn:aws:iam::611913894353:role/fhs-main-test-ire-redhataap-role"
assume_role_aws_region: "us-east-2"
assume_role_application_name: "ire-terraform-foundation-adoption"
assume_role_expected_account_id: "611913894353"

terraform_backend_bucket: "fhs-terraform-state-dev-611913894353"
terraform_backend_region: "us-east-2"

terraform_variables:
  kms_key_administrators:
    - "arn:aws:iam::611913894353:role/fhs-main-test-ire-redhataap-role"

terraform_foundation_adoption_kms_key_id: "afd1f66e-3962-4e19-923b-16c6dd347594"
terraform_foundation_adoption_kms_alias: "alias/ire-sandbox-foundation-network-firewall-logs"
terraform_foundation_adoption_standard_vault_name: "ire-sandbox-foundation-standard-backup-vault"
terraform_foundation_adoption_airgap_vault_name: "ire-sandbox-foundation-airgap-backup-vault"
