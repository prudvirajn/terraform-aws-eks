resource "aws_key_pair" "eks" {
  key_name   = "eks"
  # you can paste the public key directly like this
  #public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCk3f0HpsY29p/w34jzMUO+qkOngVfjPhDO2w4MBBU6z5fcam+W0t0qYd+fJbqsWs7jVMUWCTyGSqeQqjTlIHpJyTtRMyVJt0I9AM5JwnFxM7D+CPzDd6z2f7kL9ReY2UhfPR3rqsBOIcbVeXJYMCTwVbRZ8Z0st7DJpFwbAg435gT1bqBJgPtCC8kfTck0gt4CoaCS9n4ZCfogMVLMilNu4Enp7xLnp5d2fTg85c4kebn8kxhGs3nJhPQuW9P6SjPQt3yoFdfngF60iV2/WHwzLhJLhs+sdUz00WA9SG3qqjovLSBOtV7utEtgtCw4f3GbEgYru5g0G9KYjMA42xu1Fw90SKvqvGqjbkl+39/8mf1iNve98xiK9TD98yomrsb9aby8/7edUF++1LkEK7sZabZk//V4ctsSqlxR8owIhZNc6ufkjRF1dP5cJM5fMzPwvXNxjBW+oorGu3DwRtXMfSta34FjE5KPVlrBnYXbRn1wjtGwxs0o41jJDL19fqSXGxUFinP+iaJVxPt0txUZyhYLhpZqZkHOnK9Rg0W+QcNBPKgIS0GC2FSbj3lysoxngNKgCi1MXXcmGotf1j9G85WQMJLIfA72YhWzbCYLlUiFXsP+K4cA8kg25lqYHCWDfSoDsUaXJagF8OoeUHF7jr1hw/+0QbEouHo6lmvZUQ== ec2-user@ip-172-31-47-7.ec2.internal"

  public_key = file("/home/ec2-user/.ssh/eks.pub")
  # ~ means windows home directory
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"


  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = "1.30"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id                   = data.aws_ssm_parameter.vpc_id.value
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  create_cluster_security_group = false
  cluster_security_group_id     = local.eks_control_plane_sg_id

  create_node_security_group = false
  node_security_group_id     = local.node_sg_id

  # the user which you used to create cluster will get admin access

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {
      min_size      = 2
      max_size      = 10
      desired_size  = 2
      #capacity_type = "SPOT"
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
      # EKS takes AWS Linux 2 as it's OS to the nodes
      key_name = aws_key_pair.eks.key_name
    }
    green = {
      min_size      = 2
      max_size      = 10
      desired_size  = 2
      #capacity_type = "SPOT"
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
        ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
      # EKS takes AWS Linux 2 as it's OS to the nodes
      key_name = aws_key_pair.eks.key_name
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  tags = var.common_tags
}