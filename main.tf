provider "kubernetes" {
  config_path = "~/.kube/config" # Use your local kubeconfig path here
}

# Configure the Helm provider
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config" # Use your local kubeconfig path here
  }
}

# Create Namespace for ArgoCD
resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"
  }
}

# Deploy ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd_namespace.metadata[0].name
}

# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 
# kubectl port-forward service/argocd-server -n argocd 8080:443
# Deploy root application in argocd
resource "kubernetes_manifest" "argocd_root_dev" {
  manifest = yamldecode(templatefile("${path.module}/root.yaml", {
    path           = "development-env/applications/"
    repoURL        = "git@github.com:chak1988/argocd.git"
    targetRevision = "HEAD"
  }))
}

# resource "kubernetes_manifest" "argocd_root_prod" {
#   manifest = yamldecode(templatefile("${path.module}/root.yaml", {
#     path           = "production-env/applications/"
#     repoURL        = "git@github.com:chak1988/argocd.git"
#     targetRevision = "HEAD"
#   }))
# }
