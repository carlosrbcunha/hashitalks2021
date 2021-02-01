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

apt:
  sources:
    hashicorp:
        source: "deb https://apt.releases.hashicorp.com focal main"
        keyid: E8A032E094D8EB4EA189D270DA418C88A3219F7B

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - software-properties-common
  - python3-pip
  - unzip
  - libssl-dev
  - lsb-release
  - libffi-dev
  - python3-dev
  - wget
  - gnupg-agent
  - jq
  - net-tools
  - nomad
  