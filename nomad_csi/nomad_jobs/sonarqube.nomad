job "sonarqube" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
        attribute = "${node.unique.name}"
        operator  = "!="
        value     = "nomad-server-0"
      }
  
  group "sonarqube"{
    network {
      mode = "bridge"
      port  "sonar_db" {
            to = 5432
      }
      port  "sonar_app"  {
            to = 9000
      }
    }

    service {
        name = "sonar-db"
        task = "sonar-db"
        port = "sonar_db"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
    }
    service {
        name = "sonar-app"
        task = "sonar-app"
        tags = [ 
            "traefik.enable=true",
            "traefik.http.routers.sonarqube.entrypoints=http",
            "traefik.http.routers.sonarqube.rule=Host(`sonarqube.hashitalks2021.local`)",
            ]
        port = "sonar_app"
        check {
        name     = "sonar ui alive"
        type     = "http"
        method   = "GET"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    
      }

    volume "postgres-volume" {
      type      = "csi"
      read_only = false
      source    = "postgres-sonar"
    }

    restart {
      attempts = 2
      interval = "2m"
      delay = "25s"
      mode = "fail"
    }

    task "prep-disk" {
      driver = "docker"
      volume_mount {
        volume      = "postgres-volume"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }
      config {
        image        = "busybox:1.33.0"
        command      = "sh"
        args         = ["-c", "chown -R 999:999 /var/lib/postgresql/data"]
      }
      resources {
        cpu    = 200
        memory = 128
      }

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
    }

    task "sonar-db" {
      driver = "docker"

      volume_mount {
        volume      = "postgres-volume"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }

      template {
        data = <<EOH
POSTGRES_PASSWORD = "postgres"
POSTGRES_USER = "postgres"
POSTGRES_DB = "sonarqube"
EOH
        destination = "secrets/file.env"
        env = true
      }

      env {
        PGDATA = "/var/lib/postgresql/data/pgdata"
      }

      config  = {
        image     = "postgres:12.4"
        ulimit {
            memlock = "-1"
            nofile  = "65536"
            nproc   = "4096"
        }
      }
      resources {
        cpu    = 1500
        memory = 1024
      }
    }
    
    task "sonar-app" {

      driver = "docker"

      template {
        data = <<EOH
SONAR_JDBC_URL = "jdbc:postgresql://localhost:5432/sonarqube"
SONAR_JDBC_USERNAME = "postgres"
SONAR_JDBC_PASSWORD = "postgres"
EOH
        destination = "secrets/file.env"
        env = true
      }

      config  = {
        image     = "sonarqube:8.4.2-community"

        ulimit {
            memlock = "-1"
            nofile  = "65536"
            nproc   = "4096"
        }
      }
      resources {
        cpu    = 1000
        memory = 2048
      }
    }
  }
}
