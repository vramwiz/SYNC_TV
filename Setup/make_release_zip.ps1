param(
    [string]$ReleaseDirectory,
    [string]$XxhsumPath
)

# SYNC_WeatherFXの配布処理を元に、検証済みAUF2と対応ソースを梱包する。
# Copyright (c) 2026 VRAMの魔術師 / SPDX-License-Identifier: GPL-3.0-only
$ErrorActionPreference = 'Stop'
$packageName = 'SYNC_TV'
$projectDir = Split-Path -Parent $PSScriptRoot
$pluginName = "$packageName.auf2"
if (-not $ReleaseDirectory) {
    $ReleaseDirectory = Join-Path $env:ProgramData "aviutl2\Plugin\$packageName"
}
$pluginPath = Join-Path $ReleaseDirectory $pluginName
if (-not (Test-Path -LiteralPath $pluginPath -PathType Leaf)) {
    throw "Release plugin not found: $pluginPath. Build Win64 Release first."
}
if (-not $XxhsumPath) {
    $XxhsumPath = Join-Path $projectDir 'Win64\Dependencies\xxHash-0.8.4\xxhsum.exe'
    if (-not (Test-Path -LiteralPath $XxhsumPath -PathType Leaf)) {
        $xxhsum = Get-Command xxhsum.exe -CommandType Application -ErrorAction SilentlyContinue
        if (-not $xxhsum) { throw 'xxhsum.exe is required. See Setup\README.md.' }
        $XxhsumPath = $xxhsum.Source
    }
}
$XxhsumPath = (Resolve-Path -LiteralPath $XxhsumPath).ProviderPath

$catalogName = "$packageName.catalog.json"
$catalogPath = Join-Path $PSScriptRoot $catalogName
$zipPath = Join-Path $PSScriptRoot "$packageName.zip"
$tempBase = Join-Path $PSScriptRoot ('.release-' + [guid]::NewGuid().ToString('N'))
$tempPlugin = "$tempBase-plugin.tmp"
$tempZip = "$tempBase-zip.tmp"
$tempCatalog = "$tempBase-catalog.tmp"
$catalogBackup = "$tempBase-previous-catalog.tmp"

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$lock = [Threading.Mutex]::new($false, 'Local\VRAMWIZ.SYNC_TV.ReleaseZip')
$ownsLock = $false
try {
    try { $ownsLock = $lock.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $ownsLock = $true }
    if (-not $ownsLock) { throw 'Another release ZIP is being created. Run the batch again.' }

    $catalogSource = [IO.File]::ReadAllText($catalogPath)
    if ($catalogSource -notmatch '^\s*\[') { throw 'The catalog root must be a JSON array.' }
    $catalog = [object[]]($catalogSource | ConvertFrom-Json)
    if ($catalog.Count -ne 1 -or $catalog[0].id -cne "VRAMWIZ.$packageName") {
        throw "The catalog must contain only VRAMWIZ.$packageName."
    }
    $entry = $catalog[0]
    $github = $entry.installer.source.github
    if ($github.owner -cne 'vramwiz' -or $github.repo -cne $packageName -or
        $github.pattern -cne '^SYNC_TV\.zip$') {
        throw 'The catalog GitHub source must match this repository and ZIP name.'
    }
    $installPath = "{pluginsDir}/$packageName"
    $install = @($entry.installer.install)
    if (($install.action -join ',') -cne 'download,extract,copy' -or
        $install[2].from -cne "{tmp}/$packageName" -or $install[2].to -cne $installPath) {
        throw 'Installation must download, extract, and copy the single SYNC_TV directory.'
    }
    $uninstall = @($entry.installer.uninstall)
    if ($uninstall.Count -ne 1 -or $uninstall[0].action -cne 'delete' -or
        $uninstall[0].path -cne $installPath) {
        throw 'Uninstallation must delete only the installed SYNC_TV directory in one step.'
    }
    $versions = @($entry.version)
    if ($versions.Count -eq 0 -or $versions[0].version -cne 'v1.0.0') {
        throw 'The first public SYNC_TV version must be v1.0.0.'
    }
    $version = $versions[-1]
    $releaseDate = [datetime]::MinValue
    if ($entry.'latest-version' -cne $version.version -or $version.version -cnotmatch '^v\d+\.\d+\.\d+$' -or
        @($versions | Where-Object version -ceq $version.version).Count -ne 1 -or
        -not [datetime]::TryParseExact($version.release_date, 'yyyy-MM-dd',
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None, [ref]$releaseDate)) {
        throw 'The latest catalog version must match the last release with a valid version and date.'
    }
    $trackedFiles = @($version.file)
    if ($trackedFiles.Count -ne 1 -or $trackedFiles[0].path -cne "$installPath/$pluginName") {
        throw 'The latest catalog version must track the production AUF2.'
    }
    $tracked = $trackedFiles[0]
    if (-not $tracked.PSObject.Properties['XXH3_128'] -or $tracked.XXH3_128 -cnotmatch '^(?:[0-9a-fA-F]{32})?$') {
        throw 'The AUF2 XXH3_128 must be empty or contain exactly 32 hexadecimal digits.'
    }

    # 版表示を確認した同じバイト列をハッシュ計算と梱包に使う。
    Copy-Item -LiteralPath $pluginPath -Destination $tempPlugin
    $pluginText = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($tempPlugin))
    if (-not $pluginText.Contains("テレビ演出 / $packageName $($version.version)" + [char]0)) {
        throw "The AUF2 version must match $($version.version) in the catalog."
    }
    $hashOutput = & $XxhsumPath -H128 --tag $tempPlugin
    if ($LASTEXITCODE -ne 0 -or ($hashOutput -join [Environment]::NewLine) -notmatch ' = ([0-9a-f]{32})\s*\z') {
        throw 'Could not calculate the AUF2 XXH3-128 hash.'
    }
    $hash = $Matches[1].ToLowerInvariant()
    $updateCatalog = $tracked.XXH3_128 -cne $hash
    $catalogForArchive = $catalogPath
    if ($updateCatalog) {
        $tracked.XXH3_128 = $hash
        $json = ConvertTo-Json -InputObject $catalog -Depth 12
        [IO.File]::WriteAllText($tempCatalog, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        $catalogForArchive = $tempCatalog
    }

    $shared = @('README.md', 'LICENSE', 'THIRD_PARTY_NOTICES.md',
        'ThirdParty/LICENSE.AviUtl2-SDK.txt', 'Sample/TV_Programs.png')
    $archiveFiles = [ordered]@{}
    $archiveFiles["$packageName/$pluginName"] = $tempPlugin
    $sourcePackage = "$packageName-source"
    foreach ($name in $shared) {
        $archiveFiles["$packageName/$name"] = Join-Path $projectDir $name
        $archiveFiles["$sourcePackage/$name"] = Join-Path $projectDir $name
    }
    foreach ($name in @("$packageName.dpr", "$packageName.dproj", "$packageName.res",
        'Setup/README.md', 'Setup/make_release_zip.bat', 'Setup/make_release_zip.ps1')) {
        $archiveFiles["$sourcePackage/$name"] = Join-Path $projectDir $name
    }
    $archiveFiles["$sourcePackage/Setup/$catalogName"] = $catalogForArchive
    $sourceDir = Join-Path $projectDir 'Source'
    $sourceFiles = @(Get-ChildItem -LiteralPath $sourceDir -Recurse -File | Sort-Object FullName)
    if ($sourceFiles.Count -eq 0) { throw 'Corresponding source files were not found.' }
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($sourceDir.Length+1).Replace('\','/')
        $archiveFiles["$sourcePackage/Source/$relative"] = $file.FullName
    }
    foreach ($file in $archiveFiles.Values) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
            throw "Package file not found: $file"
        }
    }

    $zip = [IO.Compression.ZipFile]::Open($tempZip, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in $archiveFiles.GetEnumerator()) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, $file.Value, $file.Key, [IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    }
    finally { $zip.Dispose() }

    if ([IO.File]::ReadAllText($catalogPath) -cne $catalogSource) {
        throw 'Catalog changed during packaging. Run the batch again.'
    }
    if ($updateCatalog) { [IO.File]::Replace($tempCatalog, $catalogPath, $catalogBackup) }
    try {
        if ([IO.File]::Exists($zipPath)) { [IO.File]::Replace($tempZip, $zipPath, [NullString]::Value) }
        else { [IO.File]::Move($tempZip, $zipPath) }
    }
    catch {
        if ([IO.File]::Exists($catalogBackup)) {
            [IO.File]::Replace($catalogBackup, $catalogPath, [NullString]::Value)
        }
        throw
    }
    if ([IO.File]::Exists($catalogBackup)) { [IO.File]::Delete($catalogBackup) }
}
finally {
    if ($ownsLock) { $lock.ReleaseMutex() }
    $lock.Dispose()
    foreach ($tempPath in @($tempPlugin, $tempZip, $tempCatalog)) {
        [IO.File]::Delete($tempPath)
    }
}

Write-Output "Created $zipPath"
Write-Output "Catalog $catalogPath ($($version.version), XXH3_128=$hash)"
