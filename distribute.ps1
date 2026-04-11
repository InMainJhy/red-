$ErrorActionPreference = "Stop"
$projectRoot = "d:\openharmony\idea\xiaohongshu_hackathon_2026.4-main\xiaohongshu_hackathon_2026.4-main"
$distDir = Join-Path $projectRoot "distribute"
$tmpDir = Join-Path $env:TEMP "time_persona_dist_$([System.Diagnostics.Process]::GetCurrentProcess().Id)"

Write-Host "========================================"
Write-Host "   [TimePersona] Distribution Packager"
Write-Host "========================================"
Write-Host ""

Write-Host "[1/5] Checking Docker ..." -NoNewline
try {
    $v = docker --version 2>&1
    Write-Host " OK  $v"
} catch {
    Write-Host " NOT INSTALLED (recipients need Docker to deploy)" -ForegroundColor Yellow
}

Write-Host "[2/5] Validating source files ..."
$srcFiles = @(
    "backend\src\server.ts",
    "web\src\App.tsx",
    "shared\contracts.ts",
    "entry-default-signed.hap"
)
foreach ($f in $srcFiles) {
    $p = Join-Path $projectRoot $f
    if (-not (Test-Path $p)) {
        Write-Host "  MISSING: $f" -ForegroundColor Red
        exit 1
    }
    Write-Host "  OK: $f" -ForegroundColor Green
}

Write-Host "[3/5] Copying files to staging directory ..."
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

Copy-Item (Join-Path $projectRoot "backend") (Join-Path $tmpDir "backend") -Recurse -Force -Exclude node_modules
Copy-Item (Join-Path $projectRoot "web") (Join-Path $tmpDir "web") -Recurse -Force -Exclude node_modules,dist
Copy-Item (Join-Path $projectRoot "shared") (Join-Path $tmpDir "shared") -Recurse -Force
Copy-Item (Join-Path $distDir "Dockerfile.web") $tmpDir
Copy-Item (Join-Path $distDir "Dockerfile.backend") $tmpDir
Copy-Item (Join-Path $distDir "docker-compose.yml") $tmpDir
Copy-Item (Join-Path $distDir "start.bat") $tmpDir
Copy-Item (Join-Path $distDir "stop.bat") $tmpDir
Copy-Item (Join-Path $distDir "start.sh") $tmpDir
Copy-Item (Join-Path $distDir "stop.sh") $tmpDir
Copy-Item (Join-Path $distDir "README.txt") $tmpDir
Copy-Item (Join-Path $projectRoot "entry-default-signed.hap") (Join-Path $tmpDir "harmony_hap")

Write-Host "  Copying HarmonyOS source ..."
$harmonyDst = Join-Path $tmpDir "harmony"
New-Item -ItemType Directory -Path $harmonyDst -Force | Out-Null
Get-ChildItem -Path (Join-Path $projectRoot "harmony") -Force | ForEach-Object {
    $skip = $_.Name -in @("node_modules","oh_modules",".hvigor",".idea","hvigor","redmain",".git","build")
    if (-not $skip) {
        Copy-Item $_.FullName (Join-Path $harmonyDst $_.Name) -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  Done." -ForegroundColor Green

Write-Host "[4/5] Writing version file ..."
$version = Get-Date -Format "yyyyMMdd-HHmmss"
$versionFile = Join-Path $tmpDir "VERSION.txt"
$bi = "TimePersona Hackathon Distribution`nBuildTime: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nVersion: $version`n`nContents:`n- Web Frontend (React + Vite)`n- Backend API (Node.js + TypeScript)`n- PostgreSQL config`n- HarmonyOS source + HAP installer`n- Docker compose for one-click deploy`n"
[System.IO.File]::WriteAllText($versionFile, $bi, [System.Text.Encoding]::UTF8)

Write-Host "[5/5] Creating ZIP archive ..."
$zipName = "TimePersona_v$version.zip"
$zipPath = Join-Path $projectRoot $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path "$tmpDir\*" -DestinationPath $zipPath -CompressionLevel Optimal

$sz = (Get-Item $zipPath).Length
$szStr = if ($sz -gt 1GB) { "{0:N2} GB" -f ($sz/1GB) } else { "{0:N2} MB" -f ($sz/1MB) }

Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================"
Write-Host "   DONE!"
Write-Host "========================================"
Write-Host ""
Write-Host "  Archive: $zipPath"
Write-Host "  Size:    $szStr"
Write-Host ""
Write-Host "  Contents:"
Write-Host "    Web frontend + Backend API (Docker one-click deploy)"
Write-Host "    HarmonyOS full source code"
Write-Host "    entry-default-signed.hap (phone installer)"
Write-Host "    README + launch scripts"
Write-Host ""
Write-Host "  Deploy: Extract ZIP -> Run start.bat"
Write-Host ""
