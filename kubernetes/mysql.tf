resource "kubernetes_secret" "mysql-pass" {
  metadata {
    name = "mysql-pass"
  }

  data = {
    password = "Password1!"
  }

}

resource "kubernetes_manifest" "service_wordpress_mysql" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "labels" = {
        "app" = "wordpress"
      }
      "name" = "wordpress-mysql"
      "namespace" = "default"
    }
    "spec" = {
      "clusterIP" = "None"
      "ports" = [
        {
          "port" = 3306
        },
      ]
      "selector" = {
        "app" = "wordpress"
        "tier" = "mysql"
      }
    }
  }
}

resource "kubernetes_manifest" "persistentvolumeclaim_mysql_pv_claim" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "PersistentVolumeClaim"
    "metadata" = {
      "labels" = {
        "app" = "wordpress"
      }
      "name" = "mysql-pv-claim"
      "namespace" = "default"
    }
    "spec" = {
      "accessModes" = [
        "ReadWriteOnce",
      ]
      "resources" = {
        "requests" = {
          "storage" = "20Gi"
        }
      }
    }
  }
  depends_on = [
    helm_release.aws-ebs-csi-driver
  ]
}

resource "kubernetes_manifest" "deployment_wordpress_mysql" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "labels" = {
        "app" = "wordpress"
      }
      "name" = "wordpress-mysql"
      "namespace" = "default"
    }
    "spec" = {
      "selector" = {
        "matchLabels" = {
          "app" = "wordpress"
          "tier" = "mysql"
        }
      }
      "strategy" = {
        "type" = "Recreate"
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "wordpress"
            "tier" = "mysql"
          }
        }
        "spec" = {
          "containers" = [
            {
              "env" = [
                {
                  "name" = "MYSQL_ROOT_PASSWORD"
                  "valueFrom" = {
                    "secretKeyRef" = {
                      "key" = "password"
                      "name" = "mysql-pass"
                    }
                  }
                },
              ]
              "image" = "mysql:5.6"
              "name" = "mysql"
              "ports" = [
                {
                  "containerPort" = 3306
                  "name" = "mysql"
                },
              ]
              "volumeMounts" = [
                {
                  "mountPath" = "/var/lib/mysql"
                  "name" = "mysql-persistent-storage"
                },
              ]
            },
          ]
          "volumes" = [
            {
              "name" = "mysql-persistent-storage"
              "persistentVolumeClaim" = {
                "claimName" = "mysql-pv-claim"
              }
            },
          ]
        }
      }
    }
  }
}
