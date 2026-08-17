########################################
# GitHub Actions OIDC identity
########################################

variable "github_oidc_subject" {
  description = <<-EOT
    The exact subject claim GitHub presents. Copy it verbatim from the
    AADSTS700213 error in the Actions log — repos with immutable subject
    claims include numeric owner and repo IDs, e.g.
    repo:chamber-prime@312469008/azure-poc@1334321221:ref:refs/heads/main
  EOT
  type        = string
  default = "repo:chamber-prime@312469008/azure-poc@1334321221:ref:refs/heads/main"
}

resource "azurerm_user_assigned_identity" "github" {
  name                = "id-gitlab-tfstate"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
}

resource "azurerm_federated_identity_credential" "github_main" {
  name                      = "github-main-immutable"
  user_assigned_identity_id = azurerm_user_assigned_identity.github.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = var.github_oidc_subject
}

# Control plane — lets Terraform manage resources in the lab RG.
resource "azurerm_role_assignment" "github_contributor" {
  scope                = azurerm_resource_group.lab.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

# Data plane — lets the azurerm backend read and write the state blob.
# Contributor alone is not enough for this.
resource "azurerm_role_assignment" "github_blob" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

# Set this as the AZURE_CLIENT_ID repository variable in GitHub.
# Note this is client_id, not principal_id — both are GUIDs on this resource.
output "github_identity_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}
