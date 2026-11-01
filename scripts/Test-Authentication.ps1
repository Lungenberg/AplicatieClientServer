[CmdletBinding()]
param(
    [uri]$BaseUri = 'http://localhost:5050',
    [string]$Email = ('integration-' + [Guid]::NewGuid().ToString('N') + '@example.test'),
    [switch]$ExistingAccount,
    [Guid]$ExpectedUserId = [Guid]::Empty
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http

if (-not $BaseUri.IsAbsoluteUri -or -not $BaseUri.IsLoopback -or
    $BaseUri.Scheme -notin @('http', 'https')) {
    throw 'Authentication checks require an absolute loopback HTTP(S) address.'
}

# Synthetic credentials for a local integration account, never a real user password.
$testPassword = 'DriveDemo!2026'
$baseAddress = $BaseUri.AbsoluteUri.TrimEnd('/')
$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $false
$handler.CookieContainer = New-Object System.Net.CookieContainer
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromSeconds(15)
$passed = 0

function Invoke-CheckedRequest {
    param(
        [string]$Method,
        [string]$Path,
        [int]$ExpectedStatus,
        [string]$Body,
        [string]$ContentType = 'application/json',
        [string]$BearerToken,
        [switch]$WithoutCsrf,
        [string]$CsrfTokenOverride
    )

    $request = New-Object System.Net.Http.HttpRequestMessage(
        (New-Object System.Net.Http.HttpMethod($Method)), "$baseAddress$Path")
    try {
        if ($Method -notin @('GET', 'HEAD', 'OPTIONS') -and -not $WithoutCsrf) {
            $requestToken = $CsrfTokenOverride
            if (-not $PSBoundParameters.ContainsKey('CsrfTokenOverride')) {
                $tokenResponse = Invoke-CheckedRequest Get '/auth/csrf' 200
                $requestToken = ($tokenResponse.Content | ConvertFrom-Json).requestToken
            }
            if ([string]::IsNullOrWhiteSpace($requestToken)) { throw 'Missing CSRF request token.' }
            $request.Headers.Add('X-CSRF-TOKEN', $requestToken)
        }
        if ($PSBoundParameters.ContainsKey('Body')) {
            $request.Content = New-Object System.Net.Http.StringContent(
                $Body, [System.Text.Encoding]::UTF8, $ContentType)
        }
        if ($BearerToken) {
            $request.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue(
                'Bearer', $BearerToken)
        }

        $response = $client.SendAsync($request).GetAwaiter().GetResult()
        try {
            $status = [int]$response.StatusCode
            if ($status -ne $ExpectedStatus) {
                throw "$Method $Path expected HTTP $ExpectedStatus, received $status."
            }

            $setCookie = @()
            if ($response.Headers.Contains('Set-Cookie')) {
                $setCookie = @($response.Headers.GetValues('Set-Cookie'))
            }
            $script:passed++
            Write-Host "PASS: $Method $Path -> $status"
            return [pscustomobject]@{
                Content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                SetCookie = $setCookie
            }
        } finally {
            $response.Dispose()
        }
    } finally {
        $request.Dispose()
    }
}

try {
    $credentials = @{ email = $Email; password = $testPassword } | ConvertTo-Json -Compress
    Invoke-CheckedRequest Get '/health' 200 | Out-Null
    Invoke-CheckedRequest Get '/health/db' 200 | Out-Null
    Invoke-CheckedRequest Get '/auth/me' 401 | Out-Null
    Invoke-CheckedRequest Post '/auth/logout' 401 -Body '{}' | Out-Null

    $anonymousCsrf = Invoke-CheckedRequest Get '/auth/csrf' 200
    $anonymousToken = ($anonymousCsrf.Content | ConvertFrom-Json).requestToken
    Invoke-CheckedRequest Post '/auth/login?useSessionCookies=true' 400 -Body $credentials -WithoutCsrf | Out-Null

    if (-not $ExistingAccount) {
        Invoke-CheckedRequest Post '/auth/register' 400 -Body $credentials -WithoutCsrf | Out-Null
        Invoke-CheckedRequest Post '/auth/register' 400 -Body $credentials -CsrfTokenOverride 'invalid-token' | Out-Null
        $invalidEmail = @{ email = 'invalid'; password = $testPassword } | ConvertTo-Json -Compress
        Invoke-CheckedRequest Post '/auth/register' 400 -Body $invalidEmail | Out-Null
        $weakPassword = @{ email = $Email; password = 'a' } | ConvertTo-Json -Compress
        Invoke-CheckedRequest Post '/auth/register' 400 -Body $weakPassword | Out-Null
        Invoke-CheckedRequest Post '/auth/register' 200 -Body $credentials | Out-Null
        Invoke-CheckedRequest Get '/auth/me' 401 | Out-Null
        Invoke-CheckedRequest Post '/auth/register' 400 -Body $credentials | Out-Null
        $duplicate = @{ email = $Email.ToUpperInvariant(); password = $testPassword } | ConvertTo-Json -Compress
        Invoke-CheckedRequest Post '/auth/register' 400 -Body $duplicate | Out-Null
    }

    $wrongPassword = @{ email = $Email; password = 'WrongPass!1234' } | ConvertTo-Json -Compress
    Invoke-CheckedRequest Post '/auth/login?useSessionCookies=true' 401 -Body $wrongPassword | Out-Null
    $login = Invoke-CheckedRequest Post '/auth/login?useSessionCookies=true' 200 -Body $credentials
    $authCookie = @($login.SetCookie | Where-Object { $_ -match '^AcsDrive\.Auth=' })
    if ($authCookie.Count -ne 1 -or $authCookie[0] -notmatch '(?i);\s*httponly' -or
        $authCookie[0] -notmatch '(?i);\s*samesite=lax' -or
        $authCookie[0] -match '(?i);\s*(expires|max-age)=') {
        throw 'Expected one HttpOnly, SameSite=Lax session cookie.'
    }
    Write-Host 'PASS: authentication uses an HttpOnly session cookie.'

    $me = Invoke-CheckedRequest Get '/auth/me' 200
    $currentUser = $me.Content | ConvertFrom-Json
    $userId = [Guid]::Parse($currentUser.id)
    $properties = @($currentUser.PSObject.Properties.Name | Sort-Object)
    if ($currentUser.email -ne $Email -or $userId -eq [Guid]::Empty -or
        ($properties -join ',') -ne 'email,id' -or
        ($ExpectedUserId -ne [Guid]::Empty -and $userId -ne $ExpectedUserId)) {
        throw 'Current-user DTO must contain only the expected account id and email.'
    }
    Write-Host 'PASS: current-user DTO contains the correct id and email only.'

    Invoke-CheckedRequest Post '/auth/logout' 400 -Body '{}' -WithoutCsrf | Out-Null
    Invoke-CheckedRequest Post '/auth/logout' 400 -Body '{}' -CsrfTokenOverride 'invalid-token' | Out-Null
    Invoke-CheckedRequest Post '/auth/logout' 400 -Body '{}' -CsrfTokenOverride $anonymousToken | Out-Null
    Invoke-CheckedRequest Get '/auth/me' 200 | Out-Null
    Write-Host 'PASS: missing, invalid and pre-login CSRF tokens cannot log out the current account.'

    Invoke-CheckedRequest Post '/auth/logout' 400 -Body '[]' | Out-Null
    Invoke-CheckedRequest Post '/auth/logout' 400 -Body '{"unexpected":true}' | Out-Null
    Invoke-CheckedRequest Post '/auth/logout' 415 -Body '{}' -ContentType 'text/plain' | Out-Null
    Invoke-CheckedRequest Post '/auth/logout' 400 | Out-Null
    Invoke-CheckedRequest Get '/auth/logout' 405 | Out-Null
    Invoke-CheckedRequest Get '/auth/me' 200 | Out-Null
    Invoke-CheckedRequest Post '/auth/logout' 204 -Body '{}' | Out-Null
    Invoke-CheckedRequest Get '/auth/me' 401 | Out-Null

    # Built-in Identity also issues bearer tokens; our session endpoints require cookies.
    $tokens = Invoke-CheckedRequest Post '/auth/login' 200 -Body $credentials
    $accessToken = ($tokens.Content | ConvertFrom-Json).accessToken
    if ([string]::IsNullOrWhiteSpace($accessToken)) {
        throw 'Expected an Identity token from login without cookie flags.'
    }
    Invoke-CheckedRequest Get '/auth/me' 401 -BearerToken $accessToken | Out-Null
    Invoke-CheckedRequest Post '/auth/logout' 401 -Body '{}' -BearerToken $accessToken | Out-Null

    Write-Host "PASS: $passed HTTP checks and cookie/DTO assertions."
    [pscustomobject]@{ Email = $Email; UserId = $userId; HttpChecks = $passed }
} finally {
    $client.Dispose()
}
