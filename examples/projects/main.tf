module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "swedencentral"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "cognitiveservices" {
  source  = "codectl/cog/azure"
  version = "~> 1.0"

  account = {
    name                       = module.naming.cognitive_account.name_unique
    resource_group_name        = module.rg.groups.demo.name
    location                   = module.rg.groups.demo.location
    sku_name                   = "S0"
    kind                       = "AIServices"
    custom_subdomain_name      = module.naming.cognitive_account.name_unique
    project_management_enabled = true

    identity = {
      type = "SystemAssigned"
    }

    projects = {
      example = {
        identity = {
          type = "SystemAssigned"
        }
      }
    }
  }
}
