variable "conf" {
  type = object({
    gpg = optional(object({
      public_key_base64 = string
    }))
    owner = optional(string)
    repositories = map(object({
      delete_branch_on_merge = optional(string)
      description            = string
      license                = optional(string)
      topics                 = optional(list(string))
      visibility             = optional(string)
      vulnerability_alerts   = optional(string)
    }))
    ssh = optional(object({
      public_key_base64 = string
      title             = string
    }))
  })
}

variable "workflows_info" {
  type = map(object({
    name          = string
    webhook_token = string
    webhook_url   = string
  }))
}
