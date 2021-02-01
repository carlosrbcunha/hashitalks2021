#cloud-config
merge_how:
  - name: list
    settings: [append]
  - name: dict
    settings: [no_replace, recurse_list]

cloud_config_modules:
  - runcmd

cloud_final_modules:
  - scripts-user

write_files:
  - content: |
      data_dir = "/opt/nomad"

      telemetry {
        collection_interval = "1s"
        disable_hostname = true
        prometheus_metrics = true
        publish_allocation_metrics = true
        publish_node_metrics = true
      }

      autopilot {
          cleanup_dead_servers = true
          last_contact_threshold = "200ms"
          max_trailing_logs = 250
          server_stabilization_time = "10s"
          enable_redundancy_zones = false
          disable_upgrade_migration = false
          enable_custom_upgrades = false
      }
    path: /tmp/nomad.hcl
    owner: root:root
    permissions: "0644"
  - content: |
      server_join {
        retry_join = [ "${nomad_server}" ]
      }
      client {
        enabled = true
        options {
          "docker.cleanup.image.delay" = "96h"
        }
      }
      plugin "docker" {
        config {
          endpoint = "unix:///var/run/docker.sock"
        gc {
          image       = true
          image_delay = "3m"
        }
        volumes {
          enabled      = true
          selinuxlabel = "z"
        }

        allow_privileged = true
      }
    path: /tmp/client.hcl
    owner: root:root
    permissions: "0644"
  - content: |
      #!/bin/bash
      cp /tmp/nomad.hcl /etc/nomad.d/nomad.hcl
      cp /tmp/client.hcl /etc/nomad.d/client.hcl
      rm /tmp/nomad.hcl
      rm /tmp/client.hcl
      groupadd -g 5000 docker
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      apt-get -y update
      apt-get -y -q -f --reinstall install docker-ce docker-ce-cli containerd.io
      apt-get autoremove --purge
      apt-get clean
      curl -s -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/0.9.0/cni-plugins-linux-amd64-0.9.0.tgz"
      mkdir -p /opt/cni/bin
      tar -C /opt/cni/bin -xzf cni-plugins.tgz
      rm cni-plugins.tgz
      echo "nf_nat" | tee -a /etc/modules
      echo "bridge" | tee -a /etc/modules
      systemctl enable nomad
      systemctl restart docker
      systemctl restart nomad
    path: /tmp/nomad-client.sh
    owner: root:root
    permissions: "0700"

runcmd:
  - [sudo, /tmp/nomad-client.sh]
  - [sudo, rm, /tmp/nomad-client.sh]
