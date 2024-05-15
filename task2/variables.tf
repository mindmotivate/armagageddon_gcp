######## GCP Project Variables ########
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "theta-style-416117"
}

variable "credentials" {
  description = "The path to the service account key file"
  type        = string
  default     = "theta-style-416117-25814e008ac7.json"
}


variable "region" {
  type        = string
  description = "The region to deploy resources"
  default     = "us-east1"
}

variable "zone" {
  type        = string
  description = "The zone to deploy resources"
  default     = "us-east1-a"
}


##################################### HQ #################################################


# VPC name Europe Headquarters
variable "hq_vpc" {
  description = "The name of the Europe VPC"
  type        = string
  default     = "malgus-eu-vpc"
}


# VPC and Subnetwork for Europe Headquarters
variable "subnet_hq" {
  type        = string
  description = "The name of the first subnet"
  default     = "malgus-europe-subnet1"
}


variable "hq_region" {
  type        = string
  description = "The region for hq"
  default     = "europe-west1"
}

variable "hq_zone" {
  type        = string
  description = "The region for hq"
  default     = "europe-west1-b"
}


variable "hq_cidr_range" {
  type        = string
  description = "IP CIDR range for the EU HQ subnet"
  default     = "10.105.10.0/24"
}
