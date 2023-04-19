locals {
  ins = flatten([
    for kind, qty in var.bootstrap:
      [for index in range(qty) :
        kind == "master" && index == 0 ? "${kind}-leader" : "${kind}-${index}"
      ]
  ])

#  Output:
#  [
#  "master-leader",
#  "master-1",
#  "master-2",
#  "worker-0",
#   ...
#]

}