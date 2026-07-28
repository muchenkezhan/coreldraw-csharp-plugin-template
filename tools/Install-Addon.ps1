[CmdletBinding()]
param(
    [ValidatePattern('^\d{4}$')]
    [string]$CorelVersion = '',

    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',

    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-CorelAddonTarget {
    param([string]$Version)

    $uninstallRoots = @(
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    $candidates = @(
        foreach ($uninstallRoot in $uninstallRoots) {
            if (-not (Test-Path -LiteralPath $uninstallRoot)) { continue }
            foreach ($key in (Get-ChildItem -LiteralPath $uninstallRoot -ErrorAction SilentlyContinue)) {
                $properties = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction SilentlyContinue
                if (-not $properties) { continue }
                $displayNameProperty = $properties.PSObject.Properties['DisplayName']
                if (-not $displayNameProperty) { continue }
                $displayName = [string]$displayNameProperty.Value
                if ($displayName -notmatch '^CorelDRAW Graphics Suite (\d{4})$') { continue }
                $detectedVersion = $Matches[1]
                $installLocationProperty = $properties.PSObject.Properties['InstallLocation']
                if (-not $installLocationProperty) { continue }
                $installLocation = [string]$installLocationProperty.Value
                if ([string]::IsNullOrWhiteSpace($installLocation)) { continue }
                $programsDirectory = Join-Path $installLocation 'Programs64'
                $executablePath = Join-Path $programsDirectory 'CorelDRW.exe'
                if (-not (Test-Path -LiteralPath $executablePath -PathType Leaf)) { continue }
                $addonRoot = Join-Path $programsDirectory 'Addons'
                if (-not (Test-Path -LiteralPath $addonRoot -PathType Container)) { continue }

                $workspaceWriteTimeUtc = [DateTime]::MinValue
                if ($env:APPDATA) {
                    $workspaceRoot = Join-Path $env:APPDATA ("Corel\CorelDRAW Graphics Suite {0}\Draw\Workspace" -f $detectedVersion)
                    if (Test-Path -LiteralPath $workspaceRoot -PathType Container) {
                        $latestWorkspace = Get-ChildItem -LiteralPath $workspaceRoot -Filter '*.cdws' -File -ErrorAction SilentlyContinue |
                            Sort-Object LastWriteTimeUtc -Descending |
                            Select-Object -First 1
                        if ($latestWorkspace) {
                            $workspaceWriteTimeUtc = $latestWorkspace.LastWriteTimeUtc
                        }
                    }
                }
                [PSCustomObject]@{
                    Version = $detectedVersion
                    AddonRoot = $addonRoot
                    ExecutablePath = $executablePath
                    LastWorkspaceWriteTimeUtc = $workspaceWriteTimeUtc
                }
            }
        }
    )
    $candidates = @($candidates | Sort-Object Version, AddonRoot -Unique)
    if ($candidates.Count -eq 0) {
        throw '未从 Windows 安装信息中检测到可用的 CorelDRAW Programs64\Addons 目录。'
    }
    if ($Version) {
        $versionCandidates = @($candidates | Where-Object { $_.Version -eq $Version })
        if ($versionCandidates.Count -eq 0) {
            $versions = ($candidates.Version | Sort-Object -Descending -Unique) -join ', '
            throw "未检测到 CorelDRAW $Version。已安装版本：$versions"
        }
        if ($versionCandidates.Count -gt 1) {
            $locations = ($versionCandidates.AddonRoot | Sort-Object -Unique) -join '；'
            throw "CorelDRAW $Version 存在多个安装位置，请检查 Windows 安装信息：$locations"
        }
        $candidate = $versionCandidates[0]
        return [PSCustomObject]@{ Version = $candidate.Version; AddonRoot = $candidate.AddonRoot; ExecutablePath = $candidate.ExecutablePath; SelectionReason = '显式指定' }
    }
    if ($candidates.Count -eq 1) {
        $candidate = $candidates[0]
        return [PSCustomObject]@{ Version = $candidate.Version; AddonRoot = $candidate.AddonRoot; ExecutablePath = $candidate.ExecutablePath; SelectionReason = '唯一安装版本' }
    }

    $recentCandidates = @($candidates |
        Where-Object { $_.LastWorkspaceWriteTimeUtc -gt [DateTime]::MinValue } |
        Sort-Object LastWorkspaceWriteTimeUtc -Descending)
    if ($recentCandidates.Count -eq 0) {
        $versions = ($candidates.Version | Sort-Object -Descending) -join ', '
        throw "检测到多个 CorelDRAW 版本（$versions），但无法判断最近使用版本。请通过 -CorelVersion 明确指定。"
    }
    $candidate = $recentCandidates[0]
    return [PSCustomObject]@{ Version = $candidate.Version; AddonRoot = $candidate.AddonRoot; ExecutablePath = $candidate.ExecutablePath; SelectionReason = '最近使用工作区' }
}

$target = Resolve-CorelAddonTarget $CorelVersion
$targetExecutablePath = [System.IO.Path]::GetFullPath($target.ExecutablePath)
$runningTargetProcesses = @(Get-Process -Name 'CorelDRW' -ErrorAction SilentlyContinue | Where-Object {
    try { [System.IO.Path]::GetFullPath($_.Path) -ieq $targetExecutablePath } catch { $false }
})
if ($runningTargetProcesses.Count -gt 0) {
    $processIds = ($runningTargetProcesses.Id | Sort-Object) -join ", "
    throw "安装前请先关闭 CorelDRAW $($target.Version)（进程：$processIds）。其他版本可以继续运行。"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$addonSource = Join-Path $projectRoot 'addon'
$projectFile = Join-Path $projectRoot 'src\CorelDrawToolbar\CorelDrawToolbar.csproj'
if (-not $SkipBuild) {
    & dotnet build $projectFile --configuration $Configuration --nologo
    if ($LASTEXITCODE -ne 0) {
        throw 'dotnet build 失败，Addon 未安装。'
    }
}

$assemblyPath = Join-Path $projectRoot ('src\CorelDrawToolbar\bin\{0}\net48\CorelDrawToolbar.dll' -f $Configuration)
if (-not (Test-Path -LiteralPath $assemblyPath -PathType Leaf)) {
    throw "未找到构建产物：$assemblyPath"
}

$resourceBuildScript = Join-Path $projectRoot 'tools\Build-ToolbarResources.ps1'
if (-not (Test-Path -LiteralPath $resourceBuildScript -PathType Leaf)) {
    throw "未找到工具栏图标资源构建脚本：$resourceBuildScript"
}
& $resourceBuildScript -OutputDirectory $addonSource

$addonRoot = $target.AddonRoot
$targetPath = Join-Path $addonRoot 'CorelDrawToolbar'
New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
$copyPlan = @(
    [PSCustomObject]@{ Source = (Join-Path $addonSource 'CorelDrw.addon'); Destination = (Join-Path $targetPath 'CorelDrw.addon') },
    [PSCustomObject]@{ Source = (Join-Path $addonSource 'AppUI-V5.xslt'); Destination = (Join-Path $targetPath 'AppUI-V5.xslt') },
    [PSCustomObject]@{ Source = (Join-Path $addonSource 'UserUI-V5.xslt'); Destination = (Join-Path $targetPath 'UserUI-V5.xslt') },
    [PSCustomObject]@{ Source = (Join-Path $addonSource 'config.xml'); Destination = (Join-Path $targetPath 'config.xml') },
    [PSCustomObject]@{ Source = (Join-Path $addonSource 'PCodexToolbarResources.dll'); Destination = (Join-Path $targetPath 'PCodexToolbarResources.dll') },
    [PSCustomObject]@{ Source = $assemblyPath; Destination = (Join-Path $targetPath 'CorelDrawToolbar.dll') }
)
foreach ($entry in $copyPlan) {
    if (-not (Test-Path -LiteralPath $entry.Source -PathType Leaf)) {
        throw "缺少安装源文件：$($entry.Source)"
    }
    Copy-Item -LiteralPath $entry.Source -Destination $entry.Destination -Force
}

$pdbPath = [System.IO.Path]::ChangeExtension($assemblyPath, 'pdb')
if (Test-Path -LiteralPath $pdbPath -PathType Leaf) {
    Copy-Item -LiteralPath $pdbPath -Destination $targetPath -Force
}

foreach ($entry in $copyPlan) {
    if (-not (Test-Path -LiteralPath $entry.Destination -PathType Leaf)) {
        throw "部署校验失败，目标文件不存在：$($entry.Destination)"
    }
    $sourceHash = (Get-FileHash -LiteralPath $entry.Source -Algorithm SHA256).Hash
    $destinationHash = (Get-FileHash -LiteralPath $entry.Destination -Algorithm SHA256).Hash
    if ($sourceHash -ne $destinationHash) {
        throw "部署校验失败，文件哈希不一致：$($entry.Destination)"
    }
}

Write-Host "目标 CorelDRAW：$($target.Version)（$($target.SelectionReason)）" -ForegroundColor Cyan
Write-Host "Addon 已安装到：$targetPath" -ForegroundColor Green
Write-Host "已验证 $($copyPlan.Count) 个核心文件。" -ForegroundColor Green
Write-Host "工具栏名称：PCodex Demo 工具栏" -ForegroundColor Cyan
Write-Host '请重新启动 CorelDRAW，并在工具栏区域右键确认该名称。'
Write-Host '该模板使用 V5 UI 迁移文件以更新旧工作区。若仍未显示，请先备份自定义工作区，再按住 F8 启动一次。'
