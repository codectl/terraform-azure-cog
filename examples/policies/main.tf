module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
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
    name                = module.naming.cognitive_account.name_unique
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    sku_name            = "S0"
    kind                = "OpenAI"

    deployments = {
      gpt-4o = {
        model = {
          format = "OpenAI"
          name   = "gpt-4o"
        }
        sku = {
          name     = "DataZoneStandard"
          capacity = 100
        }
      }
    }
    policies = {
      example = {
        base_policy_name = "Microsoft.Default"
        content_filters = {
          filter_hate = {
            name               = "Hate"
            filter_enabled     = true
            block_enabled      = true
            severity_threshold = "High"
            source             = "Prompt"
          }
          filter_violence = {
            name               = "Violence"
            filter_enabled     = true
            block_enabled      = true
            severity_threshold = "Low"
            source             = "Completion"
          }
        }
      }
    }
  }
}
