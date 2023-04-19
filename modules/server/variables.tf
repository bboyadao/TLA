variable "servers_name" {
  type = set(string)
}
variable "image" {}
variable "profile" {
  type = list(string)
}