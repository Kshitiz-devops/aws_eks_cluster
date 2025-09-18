output "installed_charts" {
  description = "List of installed Helm releases"
  value       = keys(helm_release.this)
}
