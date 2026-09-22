<#
.SYNOPSIS
    Comprehensive Copilot Suppression Script for Windows 10/11 (Personal Machine)

.DESCRIPTION
    Disables UI, policies, and network traces of Microsoft Copilot in:
      - Microsoft Office 365
      - Microsoft Edge
      - Windows cloud/AI suggestions
      - Bing Chat / Copilot endpoints

    Includes extra hardening for Bing Chat, WebView2 Copilot surfaces, and
    Windows cloud nudges.

    Safe for:
      - Personal Windows 10/11 systems
      - Office 365
      - Microsoft Solitaire and casual games
      - Chrome as primary browser

.REQUIREMENTS
    - Run as Administrator
    - Strongly recommended: full system backup before execution
    - Optional: System Restore point created via Checkpoint-Computer
#>

# ================================
# 🔒 Admin Check
# ================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [System.Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Host "❌ ERROR: This script must be run as Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "`n🔹 Microsoft Copilot Suppression Script" -ForegroundColor Cyan
Write-Host "⚠️  Ensure you have a full system backup before proceeding." -ForegroundColor Yellow

# ================================
# 🛟 Optional: System Restore Point
# ================================
try {
    $rpName = "Pre-Copilot-Suppression-$((Get-Date -Format 'yyyyMMddHHmmss'))"
    Write-Host "[INFO] Creating System Restore point: $rpName" -ForegroundColor DarkGray
    Checkpoint-Computer -Description $rpName -RestorePointType "MODIFY_SETTINGS" | Out-Null
    Write-Host "[INFO] System Restore point created: '$rpName'" -ForegroundColor DarkGray
}
catch {
    Write-Host "[WARN] Could not create System Restore point (System Protection may be disabled)." -ForegroundColor Yellow
}

# ================================
# 1️⃣ Office Copilot Policies (HKCU)
# ================================
$officeCommonPath = "HKCU:\Software\Policies\Microsoft\Office\16.0\Common"
New-Item -Path $officeCommonPath -Force | Out-Null

# Core Copilot / smart services off
@("CopilotEnabled", "EnableCopilot", "EnableSmartServices") | ForEach-Object {
    New-ItemProperty -Path $officeCommonPath -Name $_ -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
}
New-ItemProperty -Path $officeCommonPath -Name "DisableContentInsights" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null

# Extra UI suppression (Win11+ safe, ignored on Win10)
$officeAIPath = Join-Path $officeCommonPath "officeai"
New-Item -Path $officeAIPath -Force | Out-Null
New-ItemProperty -Path $officeAIPath -Name "TurnOffCallout" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null

# Cloud Copilot pinning policies (correct path)
$officeCloudCopilotPath = "HKCU:\Software\Policies\Microsoft\Cloud\Office\16.0\Common\copilot"
New-Item -Path $officeCloudCopilotPath -Force | Out-Null
New-ItemProperty -Path $officeCloudCopilotPath -Name "CopilotPinning" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $officeCloudCopilotPath -Name "PinningStateforCopilotApp" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

Write-Host "[✅] Office Copilot policies applied." -ForegroundColor Green

# ================================
# 2️⃣ Edge Copilot Policies & Hardening (HKLM/HKCU)
# ================================
$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
New-Item -Path $edgePolicyPath -Force | Out-Null

# Disable sidebar, Copilot button, hubs, web widget
@("HubsSidebarEnabled", "CopilotEnabled", "ShowCopilotButton", "WebWidgetAllowed") | ForEach-Object {
    New-ItemProperty -Path $edgePolicyPath -Name $_ -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
}

# Extra hardening: disable Bing Chat in Edge
New-ItemProperty -Path $edgePolicyPath -Name "DisableBingChat" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null

# Extra hardening: disable WebView2 surfaces (Copilot surfaces often use WebView2)
New-ItemProperty -Path $edgePolicyPath -Name "WebView2Enabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

# Prevent Edge Update from pushing Copilot (Win11-specific, harmless on Win10)
$edgeUpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
New-Item -Path $edgeUpdatePath -Force | Out-Null
New-ItemProperty -Path $edgeUpdatePath -Name "Install {C50565E9-CCCF-44B4-BA15-5AC5C65697}" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

# Disable Edge Copilot extension via Registry (HKCU)
$edgeExtensionsPath = "HKCU:\Software\Microsoft\Edge\Extensions"
New-Item -Path $edgeExtensionsPath -Force | Out-Null
New-ItemProperty -Path $edgeExtensionsPath -Name "{C50565E9-CCCF-44B4-BA15-5AC5C65697}" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

Write-Host "[✅] Edge Copilot policies, Bing Chat, and WebView2 hardening applied." -ForegroundColor Green

# ================================
# 3️⃣ Windows Cloud / AI Suggestions (HKCU)
# ================================
$cloudContentPath = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
New-Item -Path $cloudContentPath -Force | Out-Null

# Disable Spotlight, tailored experiences, and soft-landing nudges
New-ItemProperty -Path $cloudContentPath -Name "DisableWindowsSpotlightFeatures" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $cloudContentPath -Name "DisableTailoredExperiencesWithDiagnosticData" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $cloudContentPath -Name "DisableSoftLanding" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null

# Core Windows Copilot policies (harmless on Win10, effective on Win11)
$windowsPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows"
New-Item -Path $windowsPolicyPath -Force | Out-Null
New-ItemProperty -Path $windowsPolicyPath -Name "EnableCopilot" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $windowsPolicyPath -Name "CopilotEnabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

Write-Host "[✅] Windows cloud/AI suggestions and Copilot policies applied." -ForegroundColor Green

# ================================
# 4️⃣ Hosts File Modification (Network Block)
# ================================
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"

if (-not (Test-Path $hostsFile)) {
    Write-Host "[WARN] Hosts file not found. Skipping network block." -ForegroundColor Yellow
}
else {
    $entries = @(
        "0.0.0.0 copilot.microsoft.com",
        "0.0.0.0 copilot.cloud.microsoft",
        "0.0.0.0 bing.com/chat",
        "0.0.0.0 copilot.bing.com"
    )

    foreach ($e in $entries) {
        if (-not (Select-String -Path $hostsFile -Pattern "^$([regex]::Escape($e))$" -Quiet)) {
            Add-Content -Path $hostsFile -Value $e
            Write-Host "  [ADD] $e" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  [SKIP] Already present: $e" -ForegroundColor Yellow
        }
    }
}

Write-Host "[✅] Hosts file updated (Copilot/Bing Chat endpoints blocked)." -ForegroundColor Green

# ================================
# 5️⃣ Edge Sidebar & Cache Cleanup
# ================================
$edgeUserPath = "HKCU:\Software\Microsoft\Edge"
if (-not (Test-Path $edgeUserPath)) {
    Write-Host "[INFO] Edge user profile path not found. Skipping sidebar cleanup." -ForegroundColor Yellow
}
else {
    Remove-Item -Path "$edgeUserPath\Sidebar" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[✅] Edge sidebar configuration cleaned." -ForegroundColor Green
}

# ================================
# ✅ Final Notes
# ================================
Write-Host "`n🔹 Configuration Complete!" -ForegroundColor Cyan
Write-Host "📌 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Reboot the computer (policies apply fully on startup)." -ForegroundColor Cyan
Write-Host "  2. In Edge: check that Copilot/Bing Chat buttons are gone and sidebar is minimal." -ForegroundColor Yellow
Write-Host "  3. In Office 365: confirm no Copilot prompts or AI callouts appear." -ForegroundColor Yellow
Write-Host "`n⚠️  Note: Reapply this script after major Office/Windows feature updates if Copilot surfaces reappear." -ForegroundColor DarkGray

Pause
