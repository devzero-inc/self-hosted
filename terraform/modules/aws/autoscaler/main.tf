locals {
  kubernetes_resources_labels = merge({
    "cookielab.io/terraform-module" = "aws-kube-cluster-autoscaler",
    k8s-addon                       = "cluster-autoscaler.addons.k8s.io",
  }, var.kubernetes_resources_labels)

  kubernetes_deployment_labels_selector = {
    "cookielab.io/deployment" = "aws-kube-cluster-autoscaler-tf-module",
  }

  kubernetes_deployment_labels = merge(local.kubernetes_deployment_labels_selector, local.kubernetes_resources_labels)

  kubernetes_deployment_image = "${var.kubernetes_deployment_image_registry}:${var.kubernetes_deployment_image_tag}"

  kubernetes_deployment_container_command = concat([
    "./cluster-autoscaler",
    "--v=4",
    "--stderrthreshold=info",
    "--cloud-provider=aws",
    "--skip-nodes-with-local-storage=${var.skip_nodes_with_local_storage ? "false" : "true"}",
    "--expander=${var.expander}",
    "--node-group-auto-discovery=asg:tag=${join(",", var.asg_tags)}",
    "--balance-similar-node-groups",
    "--skip-nodes-with-system-pods=false",
  ], var.additional_autoscaler_options)
}

resource "kubernetes_namespace" "cluster_autoscaler" {
  count = var.kubernetes_namespace_create ? 1 : 0

  metadata {
    name = var.kubernetes_namespace
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name = "ClusterAutoscallerBuildRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "${var.open_id_connect_provider_id_arn}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${var.open_id_connect_provider_id_url}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler",
            "${var.open_id_connect_provider_id_url}:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = var.aws_iam_policy_name
  path        = "/"
  description = "Allows access to resources needed to run kubernetes cluster autoscaler."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:DescribeLaunchConfigurations",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "kubernetes_service_account" "cluster_autoscaler" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}cluster-autoscaler"
    namespace = var.kubernetes_namespace
    labels    = local.kubernetes_resources_labels
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.cluster_autoscaler.arn}"
    }
  }
}

resource "kubernetes_cluster_role" "cluster_autoscaler" {
  metadata {
    name   = "${var.kubernetes_resources_name_prefix}cluster-autoscaler"
    labels = local.kubernetes_resources_labels
  }

  rule {
    api_groups = [""]
    resources  = ["events", "endpoints"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/eviction"]
    verbs      = ["create"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups     = [""]
    resources      = ["endpoints"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["watch", "list", "get", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["replicasets", "daemonsets"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["watch", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["statefulsets", "replicasets", "daemonsets"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "csinodes"]
    verbs      = ["watch", "list", "get"]
  }

  rule {
    api_groups = ["batch", "extensions"]
    resources  = ["jobs"]
    verbs      = ["get", "list", "watch", "patch"]
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["create"]
  }
  rule {
    api_groups     = ["coordination.k8s.io"]
    resource_names = ["cluster-autoscaler"]
    resources      = ["leases"]
    verbs          = ["get", "update"]
  }
}

resource "kubernetes_role" "cluster_autoscaler" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}cluster-autoscaler"
    namespace = kubernetes_service_account.cluster_autoscaler.metadata.0.namespace
    labels    = local.kubernetes_resources_labels
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "list", "watch"]
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    verbs          = ["delete", "get", "update", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_autoscaler" {
  metadata {
    name   = "${var.kubernetes_resources_name_prefix}cluster-autoscaler"
    labels = local.kubernetes_resources_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_autoscaler.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_autoscaler.metadata.0.name
    namespace = kubernetes_service_account.cluster_autoscaler.metadata.0.namespace
  }
}

resource "kubernetes_role_binding" "cluster_autoscaler" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}cluster-autoscaler"
    namespace = kubernetes_service_account.cluster_autoscaler.metadata.0.namespace
    labels    = local.kubernetes_resources_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.cluster_autoscaler.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_autoscaler.metadata.0.name
    namespace = kubernetes_service_account.cluster_autoscaler.metadata.0.namespace
  }
}

resource "kubernetes_deployment" "cluster_autoscaler" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}cluster-autoscaler"
    namespace = var.kubernetes_namespace
    labels    = local.kubernetes_resources_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.kubernetes_deployment_labels_selector
    }

    template {
      metadata {
        labels      = local.kubernetes_deployment_labels
        annotations = var.kubernetes_deployment_annotations
      }

      spec {
        service_account_name = kubernetes_service_account.cluster_autoscaler.metadata.0.name

        priority_class_name = var.kubernetes_priority_class_name

        container {
          image = local.kubernetes_deployment_image
          name  = "cluster-autoscaler"

          #resources {
          #  limits = {
          #    cpu    = "100m"
          #    memory = "512Mi"
          #  }
          #  requests = {
          #    cpu    = "100m"
          #    memory = "512Mi"
          #  }
          #}

          command = local.kubernetes_deployment_container_command

          volume_mount {
            name       = "ssl-certs"
            mount_path = "/etc/ssl/certs/ca-certificates.crt"
            read_only  = true
          }

          #volume_mount { # hack for automountServiceAccountToken
          #  name       = kubernetes_service_account.cluster_autoscaler.default_secret_name
          #  mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
          #  read_only  = true
          #}

          image_pull_policy = "Always"
        }

        volume {
          name = "ssl-certs"
          host_path {
            path = "/etc/ssl/certs/ca-bundle.crt"
          }
        }

        #volume { # hack for automountServiceAccountToken
        #  name = kubernetes_service_account.cluster_autoscaler.default_secret_name
        #  secret {
        #    secret_name = kubernetes_service_account.cluster_autoscaler.default_secret_name
        #  }
        #}

        node_selector = var.kubernetes_deployment_node_selector
      }
    }
  }
}

