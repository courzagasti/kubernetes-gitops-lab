param([Parameter(Mandatory=$true)][string]$Owner)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$files = @('argocd/application.yaml', 'kubernetes/deployment.yaml')
foreach ($file in $files) {
  $path = Join-Path $root $file
  $text = [System.IO.File]::ReadAllText($path)
  $text = $text.Replace('REPLACE_OWNER', $Owner.ToLowerInvariant())
  [System.IO.File]::WriteAllText($path, $text)
  Write-Host "Actualizado: $file"
}
