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
      data_dir = "/opt/nomad/data"
      server {
        enabled = true
        bootstrap_expect = 1
      }
    path: /tmp/server.hcl
    owner: root:root
    permissions: "0644"
  - content: |
      #!/bin/bash
      cp /tmp/server.hcl /etc/nomad.d/server.hcl
      rm /tmp/server.hcl
      rm /etc/nomad.d/nomad.hcl
      systemctl enable nomad
      systemctl restart nomad
    path: /tmp/nomad-server.sh
    owner: root:root
    permissions: "0700"

runcmd:
  - [sudo, /tmp/nomad-server.sh]
  - [sudo, rm, /tmp/nomad-server.sh]