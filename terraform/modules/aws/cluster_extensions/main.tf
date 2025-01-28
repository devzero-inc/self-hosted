
data "aws_subnet" "cluster_subnets" {
  for_each = toset(data.aws_eks_cluster.this.vpc_config[0].subnet_ids)
  id       = each.value
}
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}


################################################################################
# EKS Blueprints Addons
################################################################################
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.51.0"

  role_name_prefix = "${substr(data.aws_eks_cluster.this.name, 0, (38 - length("-cluster")))}-cluster"

  attach_ebs_csi_policy = true
  policy_name_prefix    = data.aws_eks_cluster.this.id

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.this.arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.19.0"

  cluster_name      = data.aws_eks_cluster.this.id
  cluster_endpoint  = data.aws_eks_cluster.this.endpoint
  cluster_version   = data.aws_eks_cluster.this.version
  oidc_provider_arn = data.aws_iam_openid_connect_provider.this.arn

  enable_aws_load_balancer_controller = true

  observability_tag = null

  eks_addons = {
    eks-pod-identity-agent = {
      most_recent = true
      preserve = false
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      preserve = false
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      configuration_values = jsonencode({
        controller = {
          podAnnotations = {
            "cluster-autoscaler.kubernetes.io/safe-to-evict" : "true"
          }
        }
      })
    }
    coredns = {
      most_recent = true
      preserve = false
    }
    vpc-cni = {
      most_recent = true
      preserve = false
    }
    kube-proxy = {
      most_recent = true
      preserve = false
    }
    snapshot-controller = {
      most_recent = true
      preserve = false
    }
    aws-efs-csi-driver = {
      most_recent = true
      preserve = false
    }
  }

  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  cluster_autoscaler = {
    chart_version = "9.43.2"
    atomic        = true
    reset_values  = true
    lint          = true
    # https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler#values
    values = [
      yamlencode({
        extraArgs = {
          "max-graceful-termination-sec" : "1800" # 30 minutes
        }
        autoDiscovery = {
          tags = [
            "k8s.io/cluster-autoscaler/enabled=true",
            "k8s.io/cluster-autoscaler/{{ .Values.autoDiscovery.clusterName }}"
          ]
        },
        podAnnotations = {
          "cluster-autoscaler.kubernetes.io/safe-to-evict" : "true",
        }
      })
    ]
  }

  tags = var.tags
}

################################################################################
# GP3 default
################################################################################

resource "kubernetes_annotations" "gp2_default" {
  annotations = {
    "storageclass.kubernetes.io/is-default-class" : "false"
  }
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }

  force = true
}

resource "kubernetes_storage_class" "gp3_default" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" : "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    fsType    = "ext4"
    encrypted = true
    type      = "gp3"
  }

  depends_on = [
    kubernetes_annotations.gp2_default,
  ]
}

################################################################################
# EFS
################################################################################

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.5"

  count = var.enable_efs ? 1: 0

  name = data.aws_eks_cluster.this.id
  encrypted = true

  performance_mode = "generalPurpose"
  throughput_mode = "elastic"

  create_backup_policy = false
  enable_backup_policy = false

  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  mount_targets = { for i, r in data.aws_eks_cluster.this.vpc_config[0].subnet_ids : "mount_${i}" => {subnet_id : r } }

  create_security_group      = true
  security_group_description = "EFS security group for ${data.aws_eks_cluster.this.id} EKS cluster"
  security_group_vpc_id      = data.aws_eks_cluster.this.vpc_config[0].vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = [for subnet in data.aws_subnet.cluster_subnets : subnet.cidr_block]
    }
  }

  tags = var.tags
}

resource "kubernetes_storage_class" "efs_etcd" {
  count = var.enable_efs ? 1: 0

  metadata {
    name = "efs-etcd"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"
  parameters = {
    basePath              = "/etcd"
    directoryPerms        = "700"
    ensureUniqueDirectory = "true"
    fileSystemId          = module.efs[0].id
    gidRangeEnd           = "2000"
    gidRangeStart         = "1000"
    provisioningMode      = "efs-ap"
    reuseAccessPoint      = "false"
    subPathPattern        = "$${.PVC.name}"
  }
}
