# Uso:  .\install.ps1              -> compila, instala em %LOCALAPPDATA%\HtmlViewer e registra no "Abrir com"
#       .\install.ps1 -Uninstall   -> remove registro, app e dados
param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'

$root   = Join-Path $env:LOCALAPPDATA 'HtmlViewer'
$dest   = Join-Path $root 'app'
$exe    = Join-Path $dest 'HtmlViewer.exe'
$cls    = 'HKCU:\Software\Classes'
$progId = 'HtmlViewer.html'
$exts   = '.html', '.htm'

if ($Uninstall) {
    Get-Process HtmlViewer -ErrorAction SilentlyContinue | Stop-Process -Force
    Remove-Item "$cls\Applications\HtmlViewer.exe", "$cls\$progId" -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($e in $exts) {
        Remove-ItemProperty "$cls\$e\OpenWithProgids" -Name $progId -ErrorAction SilentlyContinue
    }
    Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host 'HtmlViewer removido.'
    return
}

Get-Process HtmlViewer -ErrorAction SilentlyContinue | Stop-Process -Force
dotnet publish "$PSScriptRoot\HtmlViewer.csproj" -c Release -o $dest --nologo
if ($LASTEXITCODE) { throw 'dotnet publish falhou' }

$cmd = "`"$exe`" `"%1`""

# ProgID: define comando e ícone
New-Item "$cls\$progId" -Value 'Documento HTML (HtmlViewer)' -Force | Out-Null
New-Item "$cls\$progId\DefaultIcon" -Value "`"$exe`",0" -Force | Out-Null
New-Item "$cls\$progId\shell\open\command" -Value $cmd -Force | Out-Null

# Applications: nome amigável exibido no "Abrir com"
$app = "$cls\Applications\HtmlViewer.exe"
New-Item "$app\shell\open\command" -Value $cmd -Force | Out-Null
Set-ItemProperty $app -Name FriendlyAppName -Value 'HtmlViewer'
New-Item "$app\SupportedTypes" -Force | Out-Null

foreach ($e in $exts) {
    Set-ItemProperty "$app\SupportedTypes" -Name $e -Value ''
    New-Item "$cls\$e\OpenWithProgids" -Force | Out-Null
    Set-ItemProperty "$cls\$e\OpenWithProgids" -Name $progId -Value ([byte[]]@()) -Type Binary
}

Write-Host "Instalado em $dest"
Write-Host 'Clique direito num .html -> Abrir com -> HtmlViewer (marque "Sempre" para virar padrão).'
