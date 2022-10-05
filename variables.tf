variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group."
 
}

variable "tags" {
  type = map(string)
  default = {
    "name" = "Owner"
    "value" = "Arnab"
  }
}

variable "storage" {
  type = map(string)
  default = {
    "account" = "zsstorageaccount56999"
    "blobname" = "webappblob8922"
  }
}


variable "resource_group_name_prefix" {
  default     = "ARNAB-LAB-ATTACK"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

