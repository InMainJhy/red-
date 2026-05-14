# pack_harmony.ps1 - 将 harmony 目录打包，排除 .gitignore 中的文件和 build/.hvigor 等构建产物
param(
    [string]$SourceDir = "d:\openharmony\idea\xiaohongshu_hackathon_2026.4-main\xiaohongshu_hackathon_2026.4-main\harmony",
    [string]$OutDir   = "d:\openharmony\idea\xiaohongshu_hackathon_2026.4-main\xiaohongshu_hackathon_2026.4-main",
    [string]$ZipName  = "harmony_package.zip"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

# .gitignore patterns that are safe to strip at root level
$ExcludeRoots = @(
    "node_modules",
    "oh_modules",
    ".hvigor",
    ".idea",
    "hvigor",
    "redmain"
)

# Sub-path patterns to always skip
$ExcludePatterns = @(
    "build", ".cxx", ".clangd", ".clang-format", ".clang-tidy",
    ".test", ".appanalyzer", ".git", "local.properties"
)

function Test-ShouldExclude($path) {
    foreach ($p in $ExcludePatterns) {
        if ($path -match "[\/\\]$p[\/\\]" -or $path -eq $p) {
            return $true
        }
    }
    return $false
}

$resolved = if ([System.IO.Path]::IsPathRooted($OutDir)) { $OutDir } else { Join-Path $PWD $OutDir }
$outZip   = Join-Path $resolved $ZipName

Write-Host "扫描 $SourceDir ..."

# Collect all files to add
$files = @()
Get-ChildItem -Path $SourceDir -Force -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($SourceDir.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $parts = $rel -split "[\/\\]"
    $rootSkip = $false
    foreach ($part in $parts) {
        if ($ExcludeRoots -contains $part) { $rootSkip = $true; break }
    }
    if ($rootSkip) { return }
    if (Test-ShouldExclude($rel)) { return }
    $files += $_
}

Write-Host "共 $($files.Count) 个文件将被加入压缩包"

# Write to temp folder then zip
$tmpDir = Join-Path $env:TEMP "harmony_pkg_tmp_$(Get-Random -Maximum 99999)"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

$tmpRoot = Join-Path $tmpDir "harmony"
New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null

foreach ($f in $files) {
    $rel = $f.FullName.Substring($SourceDir.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $dest = Join-Path $tmpRoot $rel
    $destDir = [System.IO.Path]::GetDirectoryName($dest)
    if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item $f.FullName -Destination $dest -Force
}

Write-Host "正在压缩到 $outZip ..."
if (Test-Path $outZip) { Remove-Item $outZip -Force }

Compress-Archive -Path "$tmpRoot\*" -DestinationPath $outZip -CompressionLevel Optimal

# Also copy the signed HAP into the same output folder (if exists)
$hapSrc = "d:\openharmony\idea\xiaohongshu_hackathon_2026.4-main\xiaohongshu_hackathon_2026.4-main\harmony\entry\build\default\outputs\default\entry-default-signed.hap"
$hapDst = Join-Path $resolved "entry-default-signed.hap"
if (Test-Path $hapSrc) {
    Copy-Item $hapSrc -Destination $hapDst -Force
    Write-Host "已签名 HAP 已复制到 $hapDst"
}

# Cleanup
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

$zipSize = (Get-Item $outZip).Length
Write-Host ""
Write-Host "打包完成！"
Write-Host "  压缩包: $outZip"
Write-Host "  大小:   $([Math]::Round($zipSize/1MB, 2)) MB"
if (Test-Path $hapDst) {
    Write-Host "  HAP:    $hapDst"
}