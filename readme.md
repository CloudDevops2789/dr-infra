hello
set +H

cd "<your-working-directory>"

git clone \
  --branch feature/tagging-legacy-state-migration \
  --single-branch \
  https://github.com/CloudDevops2789/terraform_modules.git \
  terraform_modules_fv_transfer

cd terraform_modules_fv_transfer

echo "=== BRANCH ==="
git branch --show-current

echo
echo "=== HEAD ==="
git log -1 --oneline --decorate

echo
echo "=== STATUS ==="
git status --short

echo
echo "=== VERIFY LEGACY STATE INVENTORY PLAYBOOK ==="
test -f playbooks/terraform_legacy_state_inventory.yml \
  && echo "PASS: legacy state inventory playbook present" \
  || echo "FAIL: legacy state inventory playbook missing"

echo
echo "=== VERIFY FAIRVIEW TAGGING ==="
rg -n '"fv:(it_cost_center|department|cmdb_calculated_app|business_criticality|environment|data_classification|project_name|managed_by)"' \
  terraform/stacks \
  --glob '*.tf' \
  | head -n 50

echo
echo "=== VERIFY EXPECTED COMMIT ==="
git log --oneline -5
