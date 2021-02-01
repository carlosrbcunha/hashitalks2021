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
      server {
        enabled = true
        bootstrap_expect = 1
      }
    path: /etc/nomad.d/server.hcl
    permissions: "0644"

runcmd:
  - [sudo, systemctl, daemon-reload]
  - [sudo, systemctl, enable, nomad]
  - [sudo, systemctl, restart, nomad]
