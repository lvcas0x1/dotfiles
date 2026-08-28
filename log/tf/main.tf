terraform {
  required_version = ">= 1.6.0"
}

variable "name" {
  type    = string
  default = "config-test"
}

variable ":q" {

}

output "name" {
  value = var.name
}
