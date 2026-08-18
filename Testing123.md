echo "===== COMMON TAG VALUES ====="
cat terraform/environments/sandbox/stacks/common-tags.tfvars

echo
echo "===== FOUNDATION TAG VARIABLE ====="
grep -n -A 35 \
  'variable "tags"' \
  terraform/stacks/foundation/variables.tf

echo
echo "===== FOUNDATION TAG USAGE ====="
grep -R -n -E \
  'var\.tags|tags[[:space:]]*=' \
  terraform/stacks/foundation \
  --include='*.tf'

echo
echo "===== PLATFORM TAG INTERFACE ====="
grep -R -n -E \
  'variable "org_|variable "tags"|org_required|local\..*tags|tags[[:space:]]*=' \
  terraform/stacks/platform \
  --include='*.tf'
