locals {
  generation         = format("%03d", var.generation)
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  tier               = "STANDARD_HA"
  read_replicas_mode = "READ_REPLICAS_DISABLED"
}

resource "google_redis_instance" "main" {
  name           = "mem-${var.init.app.id}-${var.init.environment}-${local.generation}"
  project        = var.init.app.project_id
  tier           = local.tier
  memory_size_gb = var.memory_size_gb
  region         = var.region

  redis_version = var.redis_version
  redis_configs = var.redis_configs

  connect_mode       = local.connect_mode
  authorized_network = var.init.networks.vpc_id
  read_replicas_mode = local.read_replicas_mode

  labels = var.init.labels

  maintenance_policy {
    weekly_maintenance_window {
      day = var.maintenance_window.day
      start_time {
        hours   = var.maintenance_window.hour
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }
}

resource "kubernetes_config_map" "main_redis_connection" {
  metadata {
    name      = "${var.init.app.name}-redis-connection"
    namespace = var.init.app.name
    labels    = var.init.labels
  }
  data = {
    REDIS_HOST = google_redis_instance.main.host
    REDIS_PORT = google_redis_instance.main.port
  }
}