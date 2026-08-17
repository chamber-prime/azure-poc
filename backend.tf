terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-lab"
    storage_account_name = "sttfstatelabhpx5ry"
    container_name       = "tfstate"
    key                  = "lab.tfstate"
    use_azuread_auth     = true
  }
}
