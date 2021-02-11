variable "ceph_nodes_count" {
  default = 3
}
variable "op_nodes_count" {
  default = 1
}
# variable "opname" {}
# variable "subdomain" {}
variable "pubkey" {}
variable "user" {}

resource "google_compute_instance" "ceph_nodes" {
  count = var.ceph_nodes_count
  name = format("ceph-node-%02d", count.index+1)
  machine_type = "e2-standard-2"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  metadata = {
    ssh-keys = "${var.user}:${var.pubkey}"
  }

  labels = {
    user = var.user
    # subdomain = var.subdomain
  }
  network_interface {
    # A default network is created for all GCP projects
    network       = "default"
    access_config {
    }
  }

  attached_disk {
    source = element(google_compute_disk.ceph_node_disk.*.name, count.index)
  }
  # scheduling {
  #   preemptible = true  # the vm will be terminated in 24h or even earlier
  #   automatic_restart = false
  # }
  provisioner "remote-exec" {
    inline = [ "hostname" ]
    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      user     = var.user
      agent = true
      timeout = "10m"
    }
  }
  # provisioner "local-exec" {
  #   when = destroy
  #   command = "../deregister-op.sh ${self.labels.subdomain} ${self.labels.user}"
  #   connection {
  #     host = "localhost"
  #   }
  #   on_failure = continue
  # }
}

resource "google_compute_instance" "op_nodes" {
  count = var.op_nodes_count
  name = format("op-node-%02d", count.index+1)
  machine_type = "e2-standard-4"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  metadata = {
    ssh-keys = "${var.user}:${var.pubkey}"
  }

  labels = {
    user = var.user
    # subdomain = var.subdomain
  }
  network_interface {
    # A default network is created for all GCP projects
    network       = "default"
    access_config {
    }
  }

  attached_disk {
    source = element(google_compute_disk.op_node_disk.*.name, count.index)
  }
  # scheduling {
  #   preemptible = true  # the vm will be terminated in 24h or even earlier
  #   automatic_restart = false
  # }
  provisioner "remote-exec" {
    inline = [ "hostname" ]
    connection {
      host = self.network_interface.0.access_config.0.nat_ip
      user     = var.user
      agent = true
      timeout = "10m"
    }
  }
}

# resource "null_resource" "nodes_up" {
#   depends_on = [google_compute_instance.nodes]
#   count = var.ceph_nodes_count
#   connection {
#     host = element(google_compute_instance.nodes.*.network_interface.0.access_config.0.nat_ip, count.index)
#     user     = var.user
#     agent = true
#     timeout = "10m"
#   }
#   provisioner "remote-exec" {
#     inline = [ "hostname" ]
#   }
# }

resource "google_compute_disk" "ceph_node_disk" {
  count = var.ceph_nodes_count
  name = format("ceph-disk-%02d", count.index+1)
  # type  = "pd-hdd"
  zone  = var.google_zone
  labels = {
    environment = "dev"
  }
  physical_block_size_bytes = 4096
  size = 10
}

resource "google_compute_disk" "op_node_disk" {
  count = var.op_nodes_count
  name = format("op-disk-%02d", count.index+1)
  # type  = "pd-hdd"
  zone  = var.google_zone
  labels = {
    environment = "dev"
  }
  physical_block_size_bytes = 4096
  size = 20
}

  
resource "google_compute_firewall" "default" {
  name    = "oneprovider"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "6665", "9443"]
  }
}

resource "local_file" "ceph-ips-for-ansible" {
    count = var.ceph_nodes_count
    content     = "${join("\n", formatlist("%s ansible_host=%s ansible_user=%s", google_compute_instance.ceph_nodes.*.name, google_compute_instance.ceph_nodes.*.network_interface.0.access_config.0.nat_ip, var.user))}\n"
    filename = "${path.module}/ceph-ips.txt"
}

resource "local_file" "op-ips-for-ansible" {
    count = var.ceph_nodes_count
    content     = "${join("\n", formatlist("%s ansible_host=%s ansible_user=%s", google_compute_instance.op_nodes.*.name, google_compute_instance.op_nodes.*.network_interface.0.access_config.0.nat_ip, var.user))}\n"
    filename = "${path.module}/op-ips.txt"
}

resource "null_resource" "ansible" {
  # depends_on = [local_file.ips-for-ansible,null_resource.nodes_up]
  depends_on = [local_file.ceph-ips-for-ansible]
  provisioner "local-exec" {
    command = "../run-ansible.sh"
  }   
}

output "ceph_ips" {
  value = "${google_compute_instance.ceph_nodes}"
}

output "op_ips" {
  value = "${google_compute_instance.op_nodes}"
}

