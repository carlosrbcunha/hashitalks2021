job "pgadmin" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
        attribute = "${node.unique.name}"
        operator  = "!="
        value     = "nomad-server-0"
      }

  group "pgadmin"{
    network {
      mode = "bridge"
      port  "postgres_db" {
            to = 5432
      }
      port  "ui"  {
            to = 5050
      }
    }

    service {
        name = "postgres-db"
        task = "postgresql-db"
        port = "postgres_db"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
    }
    service {
        name = "pgadmin"
        task = "pgadmin4"
        tags = [ 
            "traefik.enable=true",
            "traefik.http.routers.pgadmin.entrypoints=http",
            "traefik.http.routers.pgadmin.rule=Host(`pgadmin.hashitalks2021.local`)",
            ]
        port = "ui"
        check {
        name     = "pgadmin ui alive"
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
      source    = "postgres-pgadmin"
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

    task "postgresql-db" {
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
POSTGRES_DB = "hashitalks2021"
EOH
        destination = "secrets/file.env"
        env = true
      }

      env {
        PGDATA = "/var/lib/postgresql/data/pgdata"
      }

      config = {
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

    task "pgadmin4" {
      driver = "docker"
      config {
        image = "dpage/pgadmin4"
        
        volumes = [
          "local/servers.json:/servers.json",
          "local/servers.passfile:/root/.pgpass"
        ]

      }
      template {
        perms = "600"
        change_mode = "noop"
        destination = "local/servers.passfile"
        data = <<EOH
localhost:5432:postgres:postgres:postgres
EOH
      }
      template {
        change_mode = "noop"
        destination = "local/servers.json"
        data = <<EOH
{
  "Servers": {
    "1": {
      "Name": "Demo Server",
      "Group": "Demo Group",
      "Port": "5432",
      "Username": "postgres",
      "PassFile": "/root/.pgpass",
      "Host": "localhost",
      "SSLMode": "disable",
      "MaintenanceDB": "postgres"
    }
  }
}
EOH
      }
      env {
        PGADMIN_DEFAULT_EMAIL="csi@hashitalks2021.com",
        PGADMIN_DEFAULT_PASSWORD="hashitalks",
        PGADMIN_LISTEN_PORT="5050"
        PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION="False"
        PGADMIN_SERVER_JSON_FILE="/servers.json"
      }

logs {
        max_files     = 5
        max_file_size = 15
      }

      resources {
        cpu = 1000
        memory = 1024
      }

      
    }


  }
}

