job "plugin-azure-disk-nodes" {
  datacenters = ["dc1"]

  # you can run node plugins as service jobs as well, but this ensures
  # that all nodes in the DC have a copy.
  type = "system"

  group "nodes" {
    task "node" {
      driver = "docker"

      template {
        change_mode = "noop"
        destination = "local/azure.json"
        data = <<EOH
{
"cloud":"AzurePublicCloud",
"tenantId": "11111111-2222-3333-4444-555555555555",
"subscriptionId": "11111111-2222-3333-4444-555555555555",
"aadClientId": "11111111-2222-3333-4444-555555555555",
"aadClientSecret": "qwertyuiopasdfghjklzxcvbnm123456",
"resourceGroup": "HashiTalks-Demo",
"location": "westeurope"
}
EOH
      }

      env {
        AZURE_CREDENTIAL_FILE = "/etc/kubernetes/azure.json"
      }

      config {
        image = "mcr.microsoft.com/k8s/csi/azuredisk-csi:v0.9.0"

        volumes = [
          "local/azure.json:/etc/kubernetes/azure.json"
        ]

        args = [
          "--nodeid=HashiTalks-Demo-${attr.unique.hostname}-vm",
          "--endpoint=unix://csi/csi.sock",
          "--logtostderr",
          "--v=5",
        ]

        # node plugins must run as privileged jobs because they
        # mount disks to the host
        privileged = true
      }

      csi_plugin {
        id        = "az-disk0"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        memory = 256
      }

      # ensuring the plugin has time to shut down gracefully
      kill_timeout = "2m"
    }
  }
}
