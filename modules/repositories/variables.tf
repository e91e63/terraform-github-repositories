variable "conf" {
  type = object({
    owner = optional(string)
    repositories = map(object({
      delete_branch_on_merge = optional(string)
      description            = string
      license                = optional(string)
      topics                 = optional(list(string))
      visibility             = optional(string)
    }))
  })
}
