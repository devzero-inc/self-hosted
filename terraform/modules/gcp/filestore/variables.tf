variable "project_id" {
  description = "The project ID in which the Filestore instance should be created"
  type        = string
}

variable "zone" {
  description = "The region in which the Filestore instance should be created"
  type        = string
}

variable "instance_name" {
  description = "The name of the Filestore instance"
  type        = string
}

variable "tier" {
  description = "The tier of the Filestore instance (STANDARD or PREMIUM)"
  type        = string
  default     = "STANDARD"
}

variable "description" {
  description = "A description for the Filestore instance"
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "The name of the network to which the Filestore instance should be connected"
  type        = string
}

variable "file_share_name" {
  description = "The name of the file share"
  type        = string
}

variable "capacity_gb" {
  description = "The capacity in GB for the file share"
  type        = number
}

variable "labels" {
  description = "A map of labels to assign to the Filestore instance"
  type        = map(string)
  default     = {}
}
