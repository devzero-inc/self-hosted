resource "google_container_node_pool" "kata_node_pool" {
  name       = "kata-node-pool"
  cluster    = var.cluster_name
  location   = var.region
  project    = var.project_id

  node_config {
    image_type   = "UBUNTU_CONTAINERD"
    machine_type = var.instance_type
    disk_size_gb = var.disk_size
    preemptible  = false

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      google-compute-enable-virtio-rng = "true"
      enable-oslogin                   = "TRUE"
      startup-script                   = <<EOT
      #!/bin/bash
      set -ex

      # Wait until containerd is running
      while ! systemctl is-active --quiet containerd; do
          sleep 2
      done

      sudo mkdir -p /etc/containerd

      if [ -f /etc/containerd/config.toml ]; then
          sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup
      fi

      cat <<EOF | sudo tee -a /etc/containerd/config.toml
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
      runtime_type = "io.containerd.kata.v2"
      privileged_without_host_devices = true

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata-qemu]
      runtime_type = "io.containerd.kata-qemu.v2"
      privileged_without_host_devices = true
      EOF

      sudo systemctl restart containerd
      EOT
    }
    tags = ["kata-runtime"]
  }

  autoscaling {
    min_node_count = var.min_size
    max_node_count = var.max_size
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_locations = [var.zone]
}
