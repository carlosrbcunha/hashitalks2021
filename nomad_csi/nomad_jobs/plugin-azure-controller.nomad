job "plugin-azure-disk-controller" {
  datacenters = ["dc1"]
  type = "service"

  group "controller" {
    count = 2

    constraint { # Don't deploy more than one instance on the same host
      distinct_hosts = true
    }

    # disable deployments
    update {
      max_parallel = 0
    }
    task "controller" {
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
        image = "mcr.microsoft.com/k8s/csi/azuredisk-csi:latest"

        volumes = [
          "local/azure.json:/etc/kubernetes/azure.json"
        ]

        args = [
          "--endpoint=unix://csi/csi.sock",
          "--logtostderr",
          "--v=5",
        ]
      }

      csi_plugin {
        id        = "az-disk0"
        type      = "controller"
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
