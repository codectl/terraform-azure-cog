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

module "kv" {
  source  = "codectl/kv/azure"
  version = "~> 1.0"

  vault = {
    name                     = module.naming.key_vault.name_unique
    location                 = module.rg.groups.demo.location
    resource_group_name      = module.rg.groups.demo.name
    purge_protection_enabled = true

    keys = {
      example = {
        key_type = "RSA"
        key_size = 2048

        key_opts = [
          "decrypt", "encrypt",
          "sign", "unwrapKey",
          "verify", "wrapKey"
        ]
      }
    }
  }
}

module "identity" {
  source  = "codectl/uai/azure"
  version = "~> 1.0"

  identity = {
    name                = module.naming.user_assigned_identity.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "cognitiveservices" {
  source  = "codectl/cog/azure"
  version = "~> 1.0"

  account = {
    name                  = module.naming.cognitive_account.name_unique
    resource_group_name   = module.rg.groups.demo.name
    location              = module.rg.groups.demo.location
    kind                  = "OpenAI"
    custom_subdomain_name = module.naming.cognitive_account.name_unique

    identity = {
      type         = "UserAssigned"
      identity_ids = [module.identity.identity.id]
    }

    role_assignments = {
      crypto = {
        scope                = module.kv.vault.id
        role_definition_name = "Key Vault Crypto Service Encryption User"
        principal_id         = module.identity.identity.principal_id
        principal_type       = "ServicePrincipal"
      }
    }

    customer_managed_key = {
      standalone         = true
      key_vault_key_id   = module.kv.keys.example.id
      identity_client_id = module.identity.identity.client_id
    }
  }
}
