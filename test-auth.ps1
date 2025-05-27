# Google Maps API Password Authentication Test Script
# Test password authentication functionality

param(
    [string]$ServerUrl = "http://localhost:3002",
    [string]$Password = "google-maps-proxy-2024"
)

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    switch ($Color) {
        "Red" { Write-Host $Text -ForegroundColor Red }
        "Green" { Write-Host $Text -ForegroundColor Green }
        "Yellow" { Write-Host $Text -ForegroundColor Yellow }
        "Blue" { Write-Host $Text -ForegroundColor Blue }
        "Cyan" { Write-Host $Text -ForegroundColor Cyan }
        "Magenta" { Write-Host $Text -ForegroundColor Magenta }
        default { Write-Host $Text -ForegroundColor White }
    }
}

function Test-ApiEndpoint {
    param(
        [string]$Url,
        [string]$Description,
        [hashtable]$Headers = @{},
        [bool]$ShouldSucceed = $true
    )
    
    Write-ColorText "Test: $Description" "Blue"
    Write-ColorText "   URL: $Url" "White"
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method GET -Headers $Headers -TimeoutSec 10
          if ($ShouldSucceed) {
            if ($response.status -eq "OK" -or $response.results -or $response.predictions -or $response.message -or $response.name -or $response.health) {
                Write-ColorText "   SUCCESS - API responded correctly" "Green"
                return $true
            } else {
                Write-ColorText "   WARNING - Unexpected API response" "Yellow"
                return $false
            }
        } else {
            Write-ColorText "   FAIL - Should have been rejected but passed" "Red"
            return $false
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        if (-not $ShouldSucceed -and ($statusCode -eq 401 -or $statusCode -eq 403)) {
            Write-ColorText "   SUCCESS - Correctly rejected invalid request" "Green"
            return $true
        } else {
            Write-ColorText "   FAIL: $($_.Exception.Message)" "Red"
            return $false
        }
    }
}

Write-ColorText "Google Maps API Proxy Password Authentication Test" "Cyan"
Write-ColorText "=================================================" "Cyan"

# Check if server is running
Write-ColorText "`nChecking server status..." "Yellow"
try {
    $healthResponse = Invoke-RestMethod -Uri "$ServerUrl/health" -TimeoutSec 5
    Write-ColorText "Server is running normally" "Green"
} catch {
    Write-ColorText "Server is not running or not accessible" "Red"
    Write-ColorText "Please start the server first: ./start.ps1" "Yellow"
    exit 1
}

$testResults = @()

Write-ColorText "`nStarting password authentication tests..." "Yellow"

# Test 1: Access API without password (should fail)
$testResults += Test-ApiEndpoint -Url "$ServerUrl/geocode/json?address=Beijing" -Description "Access geocoding API without password" -ShouldSucceed $false

# Test 2: Access API with wrong password (should fail)
$testResults += Test-ApiEndpoint -Url "$ServerUrl/geocode/json?address=Beijing&password=wrong-password" -Description "Access API with wrong password" -ShouldSucceed $false

# Test 3: Query parameter with correct password (should succeed)
$testResults += Test-ApiEndpoint -Url "$ServerUrl/geocode/json?address=Beijing&password=$Password" -Description "Query parameter authentication"

# Test 4: Request header authentication (should succeed)
$headers = @{ "X-API-Password" = $Password }
$testResults += Test-ApiEndpoint -Url "$ServerUrl/place/textsearch/json?query=restaurant" -Description "Request header authentication" -Headers $headers

# Test 5: Bearer Token authentication (should succeed)
$authHeaders = @{ "Authorization" = "Bearer $Password" }
$testResults += Test-ApiEndpoint -Url "$ServerUrl/place/autocomplete/json?input=coffee" -Description "Bearer Token authentication" -Headers $authHeaders

# Test 6: Access public endpoints (no password required, should succeed)
$testResults += Test-ApiEndpoint -Url "$ServerUrl/health" -Description "Health check endpoint (no password)"
$testResults += Test-ApiEndpoint -Url "$ServerUrl/api-status" -Description "API status endpoint (no password)"
$testResults += Test-ApiEndpoint -Url "$ServerUrl/" -Description "Root endpoint (no password)"

# Summary
$successCount = ($testResults | Where-Object { $_ }).Count
$totalCount = $testResults.Count

Write-ColorText "`nTest Results Summary" "Cyan"
Write-ColorText "===================" "Cyan"
Write-ColorText "Total tests: $totalCount" "White"
Write-ColorText "Passed: $successCount" "Green"
Write-ColorText "Failed: $($totalCount - $successCount)" "Red"

if ($successCount -eq $totalCount) {
    Write-ColorText "`nAll tests passed! Password authentication is working correctly" "Green"
    
    Write-ColorText "`nUsage examples:" "Cyan"
    Write-ColorText "   Query param: curl '$ServerUrl/geocode/json?address=Beijing&password=$Password'" "White"
    Write-ColorText "   Header: curl -H 'X-API-Password: $Password' '$ServerUrl/geocode/json?address=Beijing'" "White"
    Write-ColorText "   Bearer: curl -H 'Authorization: Bearer $Password' '$ServerUrl/geocode/json?address=Beijing'" "White"
} else {
    Write-ColorText "`nSome tests failed, please check server configuration" "Red"
}

Write-ColorText "`nSecurity reminders:" "Yellow"
Write-ColorText "   • Change default password in production" "White"
Write-ColorText "   • Use HTTPS for password transmission" "White"
Write-ColorText "   • Consider implementing rate limiting" "White"
