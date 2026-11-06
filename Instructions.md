# IRE TGW Peering — Org Requester-Side Correction

## Purpose

This document updates the TGW peering implementation for the organization environment, where the IRE Transit Gateway is the requester and the shared/Fairview Transit Gateway is the accepter.

The peering attachment already exists and is Available.

The existing peering attachment should not be imported into Terraform state unless the team explicitly decides that this Terraform stack should own the peering attachment lifecycle.

For the current design:

- the existing peering attachment remains externally managed;
- Terraform consumes the existing `tgw-attach-*` ID;
- Terraform manages the IRE-side TGW route-table association;
- Terraform manages IRE-side routes;
- Terraform manages Inspection routing and AWS Network Firewall policy;
- Terraform does not create, accept, replace, or delete the peering attachment.

## 1. Files to Change

Only these files need requester-side correction:

```text
terraform/stacks/platform/transit-gateway-peering.tf
terraform/stacks/platform/outputs.tf
terraform/stacks/platform/variables-network.tf
terraform/environments/sandbox/config/platform.tfvars
```

The existing Inspection changes do not require requester/accepter redesign.

## 2. Replace `transit-gateway-peering.tf`

File:

```text
terraform/stacks/platform/transit-gateway-peering.tf
```

Replace the complete file with:

```hcl
##################################################################################################
# External Transit Gateway Peering
##################################################################################################
#
# The Transit Gateway peering attachment already exists and is managed outside
# this Terraform stack.
#
# IRE is the requester side of the existing peering attachment.
#
# Platform consumes the existing attachment ID and manages only the IRE-side
# route-table association. Terraform does not create, accept, or delete the
# peering attachment itself.
##################################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "external_peer" {
  count = var.network_config.transit_gateway_peering.enabled ? 1 : 0

  transit_gateway_attachment_id = (
    var.network_config.transit_gateway_peering.attachment_id
  )

  transit_gateway_route_table_id = (
    module.transit_gateway.route_table_ids["external_peer"]
  )
}
```

### Important

The following resource must no longer exist anywhere in the Platform stack:

```hcl
aws_ec2_transit_gateway_peering_attachment_accepter
```

Do not replace it with a requester-side Terraform resource.

The existing attachment is intentionally treated as an external dependency.

## 3. Update `outputs.tf`

File:

```text
terraform/stacks/platform/outputs.tf
```

Inside:

```hcl
output "inspection_contract"
```

find the `external_peering` object.

Replace:

```hcl
transit_gateway_attachment_id = (
  aws_ec2_transit_gateway_peering_attachment_accepter.external[0].id
)
```

with:

```hcl
transit_gateway_attachment_id = (
  var.network_config.transit_gateway_peering.attachment_id
)
```

Do not change the other peering contract fields.

The contract should still contain values such as:

```hcl
transit_gateway_route_table_id
remote_cidrs
external_to_ire_cidrs
ire_to_external_vpc_keys
```

## 4. Update the Comment in `variables-network.tf`

File:

```text
terraform/stacks/platform/variables-network.tf
```

The current schema already contains:

```hcl
attachment_id = optional(string)
```

No schema change is required.

Only update the misleading accepter-side comment.

Replace wording similar to:

```hcl
# The IRE side acts as the accepter of a peering attachment created
# by an external/shared Transit Gateway.
```

with:

```hcl
# The peering attachment already exists and is managed externally.
# IRE consumes the existing attachment ID for its TGW routing integration.
```

Keep the existing validations for:

```text
attachment_id
remote_cidrs
external_to_ire
ire_to_external
```

unchanged.

## 5. Org `platform.tfvars`

File:

```text
terraform/environments/sandbox/config/platform.tfvars
```

The peering configuration should remain structurally like this:

```hcl
transit_gateway_peering = {
  enabled = false

  attachment_id = null

  remote_cidrs = []

  external_to_ire = {
    core_recovery = {
      subnet_groups = [
        "recovery-services"
      ]
    }

    protected_data = {
      subnet_groups = [
        "protected-workloads"
      ]
    }
  }

  ire_to_external = {
    recovery_access = {
      route_table_groups = [
        "admin-tools"
      ]
    }

    core_recovery = {
      route_table_groups = [
        "recovery-services"
      ]
    }

    protected_data = {
      route_table_groups = [
        "protected-workloads"
      ]
    }
  }
}
```

### When the real org values are confirmed

Change:

```hcl
enabled       = false
attachment_id = null
remote_cidrs  = []
```

to:

```hcl
enabled       = true
attachment_id = "tgw-attach-0df35b7cb9394ee28"

remote_cidrs = [
  # Add only approved enterprise / on-prem CIDRs here.
]
```

Do not guess `remote_cidrs`.

If the approved enterprise CIDRs are not known yet, leave:

```hcl
enabled      = false
remote_cidrs = []
```

until the Network team confirms them.

## 6. Directional Routing Meaning

### External enterprise → IRE

Controlled by:

```hcl
external_to_ire
```

Example:

```hcl
external_to_ire = {
  core_recovery = {
    subnet_groups = [
      "recovery-services"
    ]
  }
}
```

Meaning:

```text
External enterprise
        ↓
TGW peering
        ↓
external_peer TGW route table
        ↓
Inspection VPC
        ↓
AWS Network Firewall
        ↓
Core Recovery recovery-services subnets
```

If `core_recovery` is removed from `external_to_ire`, Terraform will not create inbound TGW routes for those selected Core Recovery subnet CIDRs.

The Terraform configuration remains valid.

### IRE → External enterprise

Controlled by:

```hcl
ire_to_external
```

Example:

```hcl
ire_to_external = {
  core_recovery = {
    route_table_groups = [
      "recovery-services"
    ]
  }
}
```

Meaning:

```text
Core Recovery workload
        ↓
Core Recovery VPC route table
        ↓
IRE TGW
        ↓
Inspection
        ↓
AWS Network Firewall
        ↓
TGW peering
        ↓
External enterprise
```

The two directions are intentionally independent.

## 7. Teardown Behavior

The existing peering attachment is not Terraform-owned.

Therefore a future Terraform destroy should remove IRE-managed resources such as:

```text
external_peer TGW route table
TGW route-table association
IRE-side static routes
Inspection routing
other IRE Platform resources
```

but it should not delete:

```text
tgw-attach-0df35b7cb9394ee28
```

The peering attachment remains an externally managed dependency.

This is intentional.

## 8. Validate After Making the Changes

Run from the repository root:

```bash
terraform fmt \
  terraform/stacks/platform/transit-gateway-peering.tf \
  terraform/stacks/platform/outputs.tf \
  terraform/stacks/platform/variables-network.tf \
  terraform/environments/sandbox/config/platform.tfvars

git diff --check

cd terraform/stacks/platform
terraform validate
cd ../../..
```

Expected result:

```text
Success! The configuration is valid.
```

## 9. Confirm the Accepter Resource Is Gone

Run:

```bash
grep -Rni \
'peering_attachment_accepter\|transit_gateway_peering_attachment_accepter' \
terraform/stacks/platform
```

Expected:

```text
no output
```

If any result appears, inspect it before continuing.

## 10. Check Existing TGW Route-Table Association Before Apply

Before applying, confirm whether the existing peering attachment is already associated with an IRE TGW route table.

Using AWS CLI:

```bash
aws ec2 get-transit-gateway-route-table-associations \
  --transit-gateway-route-table-id <IRE_TGW_ROUTE_TABLE_ID> \
  --output table
```

Alternatively inspect the attachment in the AWS Console under:

```text
VPC
→ Transit Gateway attachments
→ select the peering attachment
→ Association
```

The important question is:

```text
Is tgw-attach-0df35b7cb9394ee28 already associated with another IRE TGW route table?
```

Do not blindly add:

```hcl
replace_existing_association = true
```

If the attachment is already associated elsewhere, review that existing association first.

## 11. Platform PLAN Only

After:

- requester-side correction is complete;
- the attachment ID is configured;
- approved remote CIDRs are known;
- the existing TGW association is understood;

run Platform PLAN only.

Do not Apply immediately.

Review that the plan does not attempt to:

```text
create a new TGW peering attachment
accept a peering attachment
delete the existing peering attachment
replace the existing peering attachment
```

The expected peering-related changes should be limited to resources such as:

```text
external_peer TGW route table
TGW route-table association
IRE VPC routes
IRE TGW routes
Platform → Inspection contract
```

## 12. Inspection PLAN

After Platform is correct and its outputs are available, run the Inspection plan.

Review:

```text
external peer → Inspection routes
selected IRE source TGW RT → Inspection routes
Inspection TGW subnet → Network Firewall routes
Network Firewall subnet → TGW routes
Inspection TGW RT → external peering attachment
external Network Firewall IP set / policy
```

No direct external-peer → workload-VPC bypass should exist.

## 13. Desired Architecture

```text
                         EXTERNAL / ON-PREM
                                |
                        Shared/Fairview TGW
                                |
                     Existing TGW Peering
                   tgw-attach-0df35b7cb9394ee28
                                |
                         IRE Transit Gateway
                                |
                      external_peer TGW RT
                                |
                         Inspection VPC
                                |
                    AWS Network Firewall
                                |
                         IRE Transit Gateway
                                |
              +-----------------+-----------------+
              |                 |                 |
      Recovery Access      Core Recovery     Protected Data
```

Traffic from the external enterprise network must not route directly from the peering attachment to workload VPC attachments.

The Inspection VPC and AWS Network Firewall remain mandatory in the path for approved enterprise connectivity.

## Final Ownership Model

### Externally Managed

```text
Existing TGW peering attachment
Shared/Fairview TGW
Enterprise-side routing
Fairview firewall
```

### IRE Platform Terraform

```text
IRE TGW
external_peer TGW route table
peering attachment route-table association
IRE-side VPC routes
IRE-side TGW routes
Platform → Inspection contract
```

### IRE Inspection Terraform

```text
Inspection routing
AWS Network Firewall
external firewall zone
enterprise CIDR IP set
directional firewall policy
```

This is the intended org-side implementation.
