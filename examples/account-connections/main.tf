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

module "storage" {
  source  = "codectl/sa/azure"
  version = "~> 1.0"

  storage = {
    name                = module.naming.storage_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "cognitiveservices" {
  source  = "codectl/cog/azure"
  version = "~> 1.0"

  account = {
    name                       = module.naming.cognitive_account.name_unique
    resource_group_name        = module.rg.groups.demo.name
    location                   = module.rg.groups.demo.location
    kind                       = "AIServices"
    custom_subdomain_name      = module.naming.cognitive_account.name_unique
    project_management_enabled = true

    identity = {
      type = "SystemAssigned"
    }

    connections = {
      storage = {
        category = "AzureStorageAccount"
        target   = module.storage.account.primary_blob_endpoint
        metadata = {
          ApiType    = "Azure"
          ResourceId = module.storage.account.id
          location   = module.rg.groups.demo.location
        }
      }
      serp = {
        category  = "ApiKey"
        auth_type = "ApiKey"
        target    = "https://serpapi.com/search"
        api_key   = "replace-me"
        metadata = {
          ApiType = "REST"
        }
      }
    }
  }
}
