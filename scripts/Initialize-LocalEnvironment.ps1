[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $projectRoot '.env'

if (Test-Path -LiteralPath $environmentFile) {
    Write-Host 'Existing .env retained. No local settings were changed.'
    return
}

$randomBytes = New-Object byte[] 32
$randomGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try {
    $randomGenerator.GetBytes($randomBytes)
} finally {
    $randomGenerator.Dispose()
}
$databasePassword = [Convert]::ToBase64String($randomBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')

$environmentContent = @"
# Local development settings. This file is ignored by Git.
POSTGRES_DB=acs_drive
POSTGRES_USER=acs_dev
POSTGRES_PASSWORD=$databasePassword
POSTGRES_PORT=55432
"@

# CreateNew prevents an existing local configuration from being overwritten.
$fileStream = [System.IO.File]::Open($environmentFile, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
try {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $writer = New-Object System.IO.StreamWriter($fileStream, $utf8)
    try {
        $writer.WriteLine($environmentContent)
    } finally {
        $writer.Dispose()
    }
} finally {
    $fileStream.Dispose()
}

Write-Host 'Created local .env with a generated database password. The password was not printed.'
Write-Host 'Next: docker compose up -d --wait postgres'
