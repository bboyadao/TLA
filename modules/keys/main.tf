
resource "tls_private_key" "master_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "node_key" {
  algorithm = "ECDSA"
  rsa_bits  = 4096
}
