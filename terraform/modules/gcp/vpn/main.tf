# CA Key and Certificate
resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "random_id" "tls_crypt" {
  byte_length = 256
}

locals {
  tls_crypt_key_b64 = base64encode(random_id.tls_crypt.b64_std)
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "${var.name}.vpn.ca"
    organization = var.name
  }
  validity_period_hours = 9528
  is_ca_certificate     = true
  allowed_uses = ["cert_signing", "crl_signing"]
}

resource "google_secret_manager_secret" "ca_key" {
  secret_id = "${var.name}-vpn-ca-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ca_key_version" {
  secret      = google_secret_manager_secret.ca_key.id
  secret_data_wo = tls_private_key.ca.private_key_pem
}

resource "google_secret_manager_secret" "ca_cert" {
  secret_id = "${var.name}-vpn-ca-cert"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ca_cert_version" {
  secret      = google_secret_manager_secret.ca_cert.id
  secret_data_wo = tls_self_signed_cert.ca.cert_pem
}

# Server Certificate
resource "tls_private_key" "server" {
  algorithm = "RSA"
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem
  subject {
    common_name  = "${var.name}.vpn.server"
    organization = var.name
  }
  dns_names = var.additional_server_dns_names
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem      = tls_cert_request.server.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 9528
  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]
}

resource "google_secret_manager_secret" "server_key" {
  secret_id = "${var.name}-vpn-server-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "server_key_version" {
  secret      = google_secret_manager_secret.server_key.id
  secret_data_wo = tls_private_key.server.private_key_pem
}

resource "google_secret_manager_secret" "server_cert" {
  secret_id = "${var.name}-vpn-server-cert"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "server_cert_version" {
  secret      = google_secret_manager_secret.server_cert.id
  secret_data_wo = tls_locally_signed_cert.server.cert_pem
}

# VPN Instance (replace with OpenVPN setup)
resource "google_compute_instance" "vpn_server" {
  name         = "${var.name}-vpn-server"
  machine_type = var.machine_type
  zone         = var.location

  boot_disk {
    initialize_params {
      image = var.boot_image
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnet
    access_config {}
  }

  metadata = {
    vpn_name = var.name
    # Automatically provision SSH key
    ssh-keys = "ubuntu:${tls_private_key.server.public_key_openssh}"
  }

  service_account {
    email  = var.devzero_service_account
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["vpn-server"]

  depends_on = [
    google_storage_bucket.vpn_config
  ]

  # Upload OpenVPN config (or script)
  provisioner "file" {
    source      = "${path.module}/server.conf"
    destination = "/tmp/server.conf"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.server.private_key_pem
      host        = self.network_interface.0.access_config.0.nat_ip
    }
  }

  # Remote installation and configuration
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates gnupg curl",
      "echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main' | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list",
      "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg",
      "sudo apt-get update",
      "sudo apt-get install -y openvpn easy-rsa google-cloud-sdk",
      "echo '${tls_private_key.server.private_key_pem}' | sudo tee /etc/openvpn/server.key",
      "echo '${tls_locally_signed_cert.server.cert_pem}' | sudo tee /etc/openvpn/server.crt",
      "echo '${tls_self_signed_cert.ca.cert_pem}' | sudo tee /etc/openvpn/ca.crt",
      "sudo cp /tmp/server.conf /etc/openvpn/server.conf",

      "sudo openvpn --genkey --secret /etc/openvpn/tls-crypt.key",

      "echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward",
      "echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf",

      "echo 1 | sudo tee /proc/sys/net/ipv6/conf/all/forwarding",
      "echo 'net.ipv6.conf.all.forwarding=1' | sudo tee -a /etc/sysctl.conf",

      "sudo sysctl -p",

      "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections",
      "echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections",

      "sudo apt-get install -y iptables-persistent",

      "sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ens4 -j MASQUERADE",
      "sudo ip6tables -t nat -A POSTROUTING -s fd42:42:42::/64 -o ens4 -j MASQUERADE",

      "sudo netfilter-persistent save",

      <<-EOC
cat <<EOF | sudo tee /tmp/root.ovpn > /dev/null
client
dev tun
proto udp
remote ${google_compute_instance.vpn_server.network_interface.0.access_config.0.nat_ip} 443
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3

<ca>
${tls_self_signed_cert.ca.cert_pem}
</ca>

<cert>
${tls_locally_signed_cert.client["root"].cert_pem}
</cert>

<key>
${tls_private_key.client["root"].private_key_pem}
</key>

<tls-crypt>
$(sudo cat /etc/openvpn/tls-crypt.key)
</tls-crypt>
EOF
EOC
    ,

      "gsutil cp /tmp/root.ovpn gs://${google_storage_bucket.vpn_config.name}/root.ovpn",

      "sudo systemctl enable openvpn@server",
      "sudo systemctl start openvpn@server"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.server.private_key_pem
      host        = self.network_interface.0.access_config.0.nat_ip
    }
  }
}


# Firewall Rule
resource "google_compute_firewall" "vpn" {
  name    = "${var.name}-vpn-firewall"
  network = var.network

  allow {
    protocol = "udp"
    ports    = ["443"]
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vpn-server"]
}

# Client Certificates
resource "tls_private_key" "client" {
  for_each  = var.vpn_client_list
  algorithm = "RSA"
}

resource "tls_cert_request" "client" {
  for_each        = var.vpn_client_list
  private_key_pem = tls_private_key.client[each.value].private_key_pem
  subject {
    common_name  = each.value
    organization = var.name
  }
}

resource "tls_locally_signed_cert" "client" {
  for_each              = var.vpn_client_list
  cert_request_pem      = tls_cert_request.client[each.value].cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 9528
  allowed_uses = ["key_encipherment", "digital_signature", "client_auth"]
}

resource "google_secret_manager_secret" "client_key" {
  for_each   = var.vpn_client_list
  secret_id  = "${var.name}-vpn-${each.value}-client-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "client_key_version" {
  for_each    = var.vpn_client_list
  secret      = google_secret_manager_secret.client_key[each.key].id
  secret_data_wo = tls_private_key.client[each.value].private_key_pem
}

resource "google_secret_manager_secret" "client_cert" {
  for_each   = var.vpn_client_list
  secret_id  = "${var.name}-vpn-${each.value}-client-cert"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "client_cert_version" {
  for_each    = var.vpn_client_list
  secret      = google_secret_manager_secret.client_cert[each.key].id
  secret_data_wo = tls_locally_signed_cert.client[each.value].cert_pem
}

# Config Bucket
resource "google_storage_bucket" "vpn_config" {
  name                         = lower("${var.name}-vpn-config-files")
  location                     = var.bucket_location
  force_destroy                = true
  uniform_bucket_level_access  = false
}

resource "google_storage_bucket_iam_member" "bucket_access" {
  bucket = google_storage_bucket.vpn_config.name
  role   = "roles/storage.objectViewer"
  member = "projectViewer:${var.project_id}"
}