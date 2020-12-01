terraform {
  required_providers {
    hashicups = {
      source  = "interrupt-software/hashicups/custom"
      version = ">= 0.2.0"
    }
  }
}

variable "coffee_name" {
  type    = string
  default = "Vagrante espresso"
}

data "hashicups_coffees" "all" {}

# Returns all coffees
output "all_coffees" {
  value = data.hashicups_coffees.all.coffees
}

# Only returns packer spiced latte
output "coffee" {
  value = {
    for coffee in data.hashicups_coffees.all.coffees :
    coffee.id => coffee
    if coffee.name == var.coffee_name
  }
}
