[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

function Resolve-ToolbarResourceCompiler {
    $kitRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
    if (-not (Test-Path -LiteralPath $kitRoot)) {
        throw "未找到 Windows SDK 资源编译器目录：$kitRoot"
    }

    $compiler = Get-ChildItem -LiteralPath $kitRoot -Directory |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName 'x64\rc.exe' } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1
    if ($null -eq $compiler) {
        throw "未找到 x64 rc.exe。请安装 Windows 10/11 SDK。"
    }
    return $compiler
}

function Resolve-ToolbarLinker {
    $roots = @()
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
        $roots += & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    }
    $roots += @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio')
    )

    $linkerCandidates = foreach ($root in $roots | Where-Object { $_ }) {
        if (Test-Path -LiteralPath $root -PathType Container) {
            Get-ChildItem -LiteralPath $root -Recurse -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match '\\VC\\Tools\\MSVC\\[^\\]+$' } |
                Sort-Object FullName -Descending |
                ForEach-Object { Join-Path $_.FullName 'bin\Hostx64\x64\link.exe' } |
                Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
                Select-Object -First 1
        }
    }
    $linker = $linkerCandidates | Select-Object -First 1
    if ($null -eq $linker) {
        throw "未找到 x64 link.exe。请安装 Visual Studio C++ x64 生成工具。"
    }
    return $linker
}

function Write-ToolbarIcon {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Kind
    )

    Add-Type -AssemblyName System.Drawing
    $bitmap = [System.Drawing.Bitmap]::new(32, 32)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $foreground = [System.Drawing.Color]::FromArgb(31, 103, 84)
    $accent = [System.Drawing.Color]::FromArgb(33, 157, 117)
    $soft = [System.Drawing.Color]::FromArgb(226, 247, 239)
    $stroke = [System.Drawing.Pen]::new($foreground, 2.2)
    $accentBrush = [System.Drawing.SolidBrush]::new($accent)
    $softBrush = [System.Drawing.SolidBrush]::new($soft)
    $foregroundBrush = [System.Drawing.SolidBrush]::new($foreground)
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center

    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.Clear([System.Drawing.Color]::Transparent)
        switch ($Kind) {
            'rectangle' {
                $graphics.FillRectangle($softBrush, 5, 7, 22, 17)
                $graphics.DrawRectangle($stroke, 5, 7, 22, 17)
                $graphics.DrawLine($stroke, 8, 22, 24, 22)
            }
            'text' {
                $font = [System.Drawing.Font]::new('Segoe UI', 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
                try { $graphics.DrawString('T', $font, $foregroundBrush, [System.Drawing.RectangleF]::new(0, 1, 32, 29), $format) } finally { $font.Dispose() }
            }
            'sample' {
                $graphics.FillEllipse($softBrush, 4, 7, 12, 12)
                $graphics.FillEllipse($accentBrush, 15, 5, 13, 13)
                $graphics.FillEllipse($foregroundBrush, 11, 16, 13, 13)
            }
            'duplicate' {
                $graphics.DrawRectangle($stroke, 5, 9, 15, 15)
                $graphics.FillRectangle($softBrush, 12, 5, 15, 15)
                $graphics.DrawRectangle($stroke, 12, 5, 15, 15)
            }
            'center' {
                $graphics.DrawEllipse($stroke, 7, 7, 18, 18)
                $graphics.DrawLine($stroke, 3, 16, 29, 16)
                $graphics.DrawLine($stroke, 16, 3, 16, 29)
                $graphics.FillEllipse($accentBrush, 13, 13, 6, 6)
            }
            'fill' {
                $points = [System.Drawing.Point[]]@(
                    [System.Drawing.Point]::new(16, 4),
                    [System.Drawing.Point]::new(25, 15),
                    [System.Drawing.Point]::new(21, 25),
                    [System.Drawing.Point]::new(11, 25),
                    [System.Drawing.Point]::new(7, 15)
                )
                $graphics.FillPolygon($accentBrush, $points)
                $graphics.DrawPolygon($stroke, $points)
            }
            'info' {
                $graphics.FillEllipse($softBrush, 5, 5, 22, 22)
                $graphics.DrawEllipse($stroke, 5, 5, 22, 22)
                $font = [System.Drawing.Font]::new('Segoe UI', 16, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
                try { $graphics.DrawString('i', $font, $foregroundBrush, [System.Drawing.RectangleF]::new(0, 1, 32, 30), $format) } finally { $font.Dispose() }
            }
            'settings' {
                $graphics.DrawLine($stroke, 6, 8, 26, 8)
                $graphics.DrawLine($stroke, 6, 16, 26, 16)
                $graphics.DrawLine($stroke, 6, 24, 26, 24)
                $graphics.FillEllipse($accentBrush, 10, 4, 8, 8)
                $graphics.FillEllipse($accentBrush, 18, 12, 8, 8)
                $graphics.FillEllipse($accentBrush, 8, 20, 8, 8)
            }
            'about' {
                $graphics.FillEllipse($softBrush, 4, 4, 24, 24)
                $graphics.DrawEllipse($stroke, 4, 4, 24, 24)
                $font = [System.Drawing.Font]::new('Segoe UI', 15, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
                try { $graphics.DrawString('P', $font, $foregroundBrush, [System.Drawing.RectangleF]::new(0, 1, 32, 30), $format) } finally { $font.Dispose() }
            }
            default {
                $graphics.FillEllipse($foregroundBrush, 6, 13, 5, 5)
                $graphics.FillEllipse($foregroundBrush, 14, 13, 5, 5)
                $graphics.FillEllipse($foregroundBrush, 22, 13, 5, 5)
            }
        }

        $iconHandle = $bitmap.GetHicon()
        $icon = [System.Drawing.Icon]::FromHandle($iconHandle)
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        try { $icon.Save($stream) } finally { $stream.Dispose(); $icon.Dispose() }
    }
    finally {
        $format.Dispose()
        $foregroundBrush.Dispose()
        $softBrush.Dispose()
        $accentBrush.Dispose()
        $stroke.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$entries = @(
    [PSCustomObject]@{ StringId = 1001; IconId = 101; Caption = '页面比例矩形'; FileName = 'page-rectangle.ico'; Kind = 'rectangle' }
    [PSCustomObject]@{ StringId = 1002; IconId = 102; Caption = 'PCodex 艺术字'; FileName = 'artistic-text.ico'; Kind = 'text' }
    [PSCustomObject]@{ StringId = 1003; IconId = 103; Caption = 'PCodex 组合样例'; FileName = 'sample.ico'; Kind = 'sample' }
    [PSCustomObject]@{ StringId = 1004; IconId = 104; Caption = '复制并偏移'; FileName = 'duplicate.ico'; Kind = 'duplicate' }
    [PSCustomObject]@{ StringId = 1005; IconId = 105; Caption = '居中到页面'; FileName = 'center.ico'; Kind = 'center' }
    [PSCustomObject]@{ StringId = 1006; IconId = 106; Caption = '应用当前填充'; FileName = 'fill.ico'; Kind = 'fill' }
    [PSCustomObject]@{ StringId = 1007; IconId = 107; Caption = '显示选区信息'; FileName = 'selection-info.ico'; Kind = 'info' }
    [PSCustomObject]@{ StringId = 1008; IconId = 108; Caption = '编辑默认参数'; FileName = 'settings.ico'; Kind = 'settings' }
    [PSCustomObject]@{ StringId = 1009; IconId = 109; Caption = '关于 PCodex Demo'; FileName = 'about.ico'; Kind = 'about' }
    [PSCustomObject]@{ StringId = 1010; IconId = 110; Caption = '更多功能'; FileName = 'more-tools.ico'; Kind = 'more' }
)

$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$assetDirectory = Join-Path $OutputDirectory '.toolbar-resources'
$resourceScript = Join-Path $assetDirectory 'PCodexToolbarResources.rc'
$resourceObject = Join-Path $assetDirectory 'PCodexToolbarResources.res'
$resourceDll = Join-Path $OutputDirectory 'PCodexToolbarResources.dll'
New-Item -ItemType Directory -Path $assetDirectory -Force | Out-Null

foreach ($entry in $entries) {
    Write-ToolbarIcon -Path (Join-Path $assetDirectory $entry.FileName) -Kind $entry.Kind
}

$resourceLines = @(
    '#pragma code_page(65001)',
    ''
    'STRINGTABLE',
    'BEGIN'
)
foreach ($entry in $entries) {
    $resourceLines += '    {0} "{1}"' -f $entry.StringId, $entry.Caption.Replace('"', '\"')
}
$resourceLines += @('END', '')
foreach ($entry in $entries) {
    $resourceLines += '{0} ICON "{1}"' -f $entry.IconId, $entry.FileName
}
Set-Content -LiteralPath $resourceScript -Value ($resourceLines -join [Environment]::NewLine) -Encoding utf8

$resourceCompiler = Resolve-ToolbarResourceCompiler
$linker = Resolve-ToolbarLinker
$env:PATH = (Split-Path -Parent $linker) + ';' + $env:PATH
& $resourceCompiler '/nologo' ('/fo' + $resourceObject) $resourceScript
if ($LASTEXITCODE -ne 0) { throw "rc.exe 构建图标资源失败。" }
& $linker '/nologo' '/dll' '/noentry' '/machine:x64' ('/out:' + $resourceDll) $resourceObject
if ($LASTEXITCODE -ne 0) { throw "link.exe 生成资源 DLL 失败。" }
if (-not (Test-Path -LiteralPath $resourceDll -PathType Leaf)) {
    throw "未生成 CorelDRAW 工具栏资源 DLL：$resourceDll"
}

Write-Host "已生成工具栏图标资源：$resourceDll" -ForegroundColor Green
