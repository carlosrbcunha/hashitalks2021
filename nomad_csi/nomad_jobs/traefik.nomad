job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"
  
  constraint {
        attribute = "${node.unique.name}"
        operator  = "="
        value     = "nomad-server-0"
      }
  group "traefik" {
    count = 1

    network {
          port "http" {
            static = 80
          }

          port "https" {
              static = 443
          }

          port "api" {
            static = 8080
          }
        }
    
    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.4.2"
        network_mode = "host"

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml"
        ]
      }

      env {
      }

      template {
        data = <<EOF
[entryPoints]
    [entryPoints.traefik]
        address = ":8080"
    [entryPoints.http]
        address = ":80"

[api]
    dashboard = true
    insecure  = true

[log]
    level = "DEBUG"
[accessLog]
    format = "json"

[metrics]
    [metrics.influxdb]
        address = "localhost:8086"
        protocol = "http"
        pushinterval = "60s"
        database = "traefik"
        retentionpolicy = "traefik"

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false
    requireConsistent = true

    [providers.consulCatalog.endpoint]
        address = "127.0.0.1:8500"
        scheme  = "http"
        datacenter = "dc1"
EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name = "traefik"
        tags = [
          
        ]

        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}