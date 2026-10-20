[CmdletBinding()]
param(
    # Recreate only this project's PostgreSQL container to verify volume persistence.
    [switch]$RecreateContainer
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $projectRoot 'compose.yaml'
$verificationDatabase = 'acs_verify_' + [Guid]::NewGuid().ToString('N')
$databaseCreated = $false

function Invoke-ProjectCompose {
    param([string[]]$Arguments)

    $result = & docker compose --file $composeFile --project-name acs-drive @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw 'Project Docker Compose command failed.'
    }
    return $result
}

function Invoke-DatabaseSql {
    param([string]$Sql, [string]$Database = 'postgres')

    if ($Database -notmatch '^[a-z0-9_]+$') {
        throw 'Unexpected verification database name.'
    }

    # Read credentials inside the container, without printing or passing a password on the command line.
    $clientCommand = 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --host=postgres --username="$POSTGRES_USER" --dbname="$ACS_CHECK_DB" --no-psqlrc --quiet --tuples-only --no-align --set=ON_ERROR_STOP=1'
    $result = $Sql | & docker compose --file $composeFile --project-name acs-drive exec -T --env "ACS_CHECK_DB=$Database" postgres sh -c $clientCommand
    if ($LASTEXITCODE -ne 0) {
        throw 'PostgreSQL verification query failed.'
    }
    return $result
}

function Get-ProjectDataVolume {
    param([string]$ContainerId)

    $mountJson = & docker inspect --format '{{json .Mounts}}' $ContainerId
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not inspect PostgreSQL data volume.'
    }
    $mounts = $mountJson | ConvertFrom-Json
    $dataMount = @($mounts | Where-Object { $_.Destination -eq '/var/lib/postgresql' -and $_.Type -eq 'volume' })
    if ($dataMount.Count -ne 1 -or $dataMount[0].Name -ne 'acs-drive_postgres-data') {
        throw 'Expected project-owned named volume is missing. Container recreation was not attempted.'
    }
    return $dataMount[0].Name
}

Push-Location $projectRoot
try {
    Invoke-ProjectCompose -Arguments @('up', '-d', '--wait', '--wait-timeout', '90', 'postgres') | Out-Host

    $publishedAddress = (Invoke-ProjectCompose -Arguments @('port', 'postgres', '5432')).Trim()
    if ($publishedAddress -notmatch '^127\.0\.0\.1:(\d+)$') {
        throw 'Expected a PostgreSQL port published only on loopback.'
    }
    $publishedPort = [int]$Matches[1]
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        $connection = $tcpClient.ConnectAsync('127.0.0.1', $publishedPort)
        if (-not $connection.Wait(5000)) { throw 'Local PostgreSQL port did not respond.' }
        [void]$connection.GetAwaiter().GetResult()
    } finally {
        $tcpClient.Dispose()
    }
    Write-Host "PASS: local TCP port $publishedPort is reachable."

    $containerBefore = (Invoke-ProjectCompose -Arguments @('ps', '--quiet', 'postgres')).Trim()
    $volumeBefore = Get-ProjectDataVolume -ContainerId $containerBefore
    $serverVersion = Invoke-DatabaseSql -Sql 'SHOW server_version;'
    Write-Host "PASS: SQL connection succeeded (PostgreSQL $serverVersion)."

    Invoke-DatabaseSql -Sql "CREATE DATABASE $verificationDatabase;" | Out-Null
    $databaseCreated = $true
    $setupSql = @'
CREATE TABLE persistence_probe (
    id integer PRIMARY KEY,
    label text NOT NULL
);
INSERT INTO persistence_probe (id, label) VALUES (1, 'acs-drive-persistence');
BEGIN;
INSERT INTO persistence_probe (id, label) VALUES (2, 'must-be-rolled-back');
ROLLBACK;
SELECT count(*) FROM persistence_probe;
'@
    $rowCount = (Invoke-DatabaseSql -Database $verificationDatabase -Sql $setupSql).Trim()
    if ($rowCount -ne '1') { throw 'Transaction rollback verification failed.' }
    Write-Host 'PASS: a committed row is present; the rolled-back row is absent.'

    if ($RecreateContainer) {
        Write-Host 'Recreating this project database container; its named volume is retained.'
        Invoke-ProjectCompose -Arguments @('up', '-d', '--force-recreate', '--wait', '--wait-timeout', '90', 'postgres') | Out-Host
        $containerAfter = (Invoke-ProjectCompose -Arguments @('ps', '--quiet', 'postgres')).Trim()
        $volumeAfter = Get-ProjectDataVolume -ContainerId $containerAfter
        if ($containerAfter -eq $containerBefore -or $volumeAfter -ne $volumeBefore) {
            throw 'Container recreation or volume identity verification failed.'
        }
    }

    $persistedRow = (Invoke-DatabaseSql -Database $verificationDatabase -Sql 'SELECT label FROM persistence_probe WHERE id = 1;').Trim()
    $remainingRows = (Invoke-DatabaseSql -Database $verificationDatabase -Sql 'SELECT count(*) FROM persistence_probe;').Trim()
    if ($persistedRow -ne 'acs-drive-persistence' -or $remainingRows -ne '1') {
        throw 'Stored data verification failed.'
    }
    if ($RecreateContainer) {
        Write-Host 'PASS: the row survived container replacement using the same named volume.'
    } else {
        Write-Host 'PASS: the stored row can be read back. Use -RecreateContainer to verify persistence across container replacement.'
    }
} finally {
    try {
        if ($databaseCreated) {
            Invoke-DatabaseSql -Sql "DROP DATABASE $verificationDatabase;" | Out-Null
            Write-Host 'Removed only the temporary verification database. Application data was not changed.'
        }
    } finally {
        Pop-Location
    }
}
