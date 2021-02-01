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
      #!/bin/bash
      sudo apt-get -y -q update
      sudo apt-get -y -q install apt-transport-https ca-certificates curl software-properties-common python3-pip unzip libssl-dev lsb-release libffi-dev python3-dev wget gnupg-agent jq net-tools
      curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
      sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
      sudo apt-get -y -q install nomad
      sudo rm /opt/nomad.d/nomad.hcl
      grep -qxF 'vm.max_map_count=262144' /etc/sysctl.conf || sudo echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.conf
    path: /tmp/nomad-common.sh
    owner: root:root
    permissions: "0700"

runcmd:
  - [sudo, /tmp/nomad-common.sh]
  - [sudo, rm, /tmp/nomad-common.sh]

