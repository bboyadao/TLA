
variable "bootstrap" {
  type = map(string)
  default = {
    "master" : 2,
    "worker" : 1
  }
}