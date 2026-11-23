# Baixa as fontes do Synapse Zero para app/assets/fonts (licença OFL 1.1).
#
# Uso (na pasta app, no PowerShell):
#   powershell -ExecutionPolicy Bypass -File tool\fetch_fonts.ps1
#
# Executar uma vez por clone. Depois, versione os arquivos baixados
# (git add -A) para que o outro ambiente os receba com git pull.
# Cada arquivo é validado (cabeçalho TrueType/OpenType); qualquer falha
# interrompe o script com a causa.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dest = Join-Path $PSScriptRoot '..\assets\fonts'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$dest = (Resolve-Path $dest).Path

$google = 'https://github.com/google/fonts/raw/main/ofl/unbounded'
$plex = 'https://github.com/IBM/plex/raw/master/packages'

$files = @(
    @{ Name = 'Unbounded-Variable.ttf'; Url = "$google/Unbounded%5Bwght%5D.ttf"; Font = $true },
    @{ Name = 'Unbounded-OFL.txt'; Url = "$google/OFL.txt"; Font = $false },
    @{ Name = 'IBMPlexSans-Regular.ttf'; Url = "$plex/plex-sans/fonts/complete/ttf/IBMPlexSans-Regular.ttf"; Font = $true },
    @{ Name = 'IBMPlexSans-Medium.ttf'; Url = "$plex/plex-sans/fonts/complete/ttf/IBMPlexSans-Medium.ttf"; Font = $true },
    @{ Name = 'IBMPlexSans-SemiBold.ttf'; Url = "$plex/plex-sans/fonts/complete/ttf/IBMPlexSans-SemiBold.ttf"; Font = $true },
    @{ Name = 'IBMPlexMono-Regular.ttf'; Url = "$plex/plex-mono/fonts/complete/ttf/IBMPlexMono-Regular.ttf"; Font = $true },
    @{ Name = 'IBMPlexMono-Medium.ttf'; Url = "$plex/plex-mono/fonts/complete/ttf/IBMPlexMono-Medium.ttf"; Font = $true },
    @{ Name = 'IBMPlex-OFL.txt'; Url = 'https://github.com/IBM/plex/raw/master/LICENSE.txt'; Font = $false }
)

foreach ($f in $files) {
    $path = Join-Path $dest $f.Name
    Write-Host "Baixando $($f.Name) ..."
    Invoke-WebRequest -Uri $f.Url -OutFile $path -UseBasicParsing

    $bytes = [IO.File]::ReadAllBytes($path)
    if ($bytes.Length -lt 1024) {
        Remove-Item $path -Force
        throw "$($f.Name): arquivo muito pequeno ($($bytes.Length) bytes). URL: $($f.Url)"
    }
    if ($f.Font) {
        $magic = [Text.Encoding]::ASCII.GetString($bytes, 0, 4)
        $isTrueType = ($bytes[0] -eq 0 -and $bytes[1] -eq 1 -and $bytes[2] -eq 0 -and $bytes[3] -eq 0)
        if (-not ($isTrueType -or $magic -eq 'OTTO' -or $magic -eq 'true')) {
            Remove-Item $path -Force
            throw "$($f.Name): não é uma fonte válida (cabeçalho inesperado). URL: $($f.Url)"
        }
    }
}

Write-Host ''
Write-Host "Concluído: $($files.Count) arquivos em $dest"
