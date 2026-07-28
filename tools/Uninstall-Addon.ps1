[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidatePattern('^\d{4}$')]
    [string]$CorelVersion = ''
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
    throw "卸载前请先关闭 CorelDRAW $($target.Version)（进程：$processIds）。其他版本可以继续运行。"
}

$addonRoot = $target.AddonRoot
$targetPath = Join-Path $addonRoot 'CorelDrawToolbar'
$manifestPath = Join-Path $targetPath 'CorelDrw.addon'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "未找到此模板的 Addon 清单：$manifestPath"
}

[xml]$manifest = Get-Content -LiteralPath $manifestPath -Raw
if ([string]$manifest.Addon.Name -ne 'CorelDrawToolbar') {
    throw '目标目录中的 Addon 名称不匹配，已拒绝删除。'
}

if ($PSCmdlet.ShouldProcess($targetPath, '删除 CorelDRAW Addon')) {
    Remove-Item -LiteralPath $targetPath -Recurse -Force
    Write-Host "目标 CorelDRAW：$($target.Version)（$($target.SelectionReason)）" -ForegroundColor Cyan
    Write-Host "Addon 已卸载：$targetPath" -ForegroundColor Green
}
