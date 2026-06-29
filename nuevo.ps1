param([string]$t, [switch]$nota)

$date = Get-Date -Format "yyyy-MM-dd"
$slug = $t -replace '[^\w\s-]','' -replace '\s+','-' -replace '_+','-' -replace '-+','-'
$filename = "$date-$slug.md"

if ($nota) {
  $body = @"
---
date: $date
categories:
  - 
---
$t
"@
  $folder = "src\micro"
} else {
  $body = @"
---
title: "$t"
date: $date
categories:
  - 
---
Escribir aca...
"@
  $folder = "src\posts"
}

$path = Join-Path "." $folder $filename
Set-Content -LiteralPath $path -Value $body -Encoding UTF8
Write-Host "Creado: $folder\$filename"
