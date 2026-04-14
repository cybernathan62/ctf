$ErrorActionPreference = "Stop"

$Key = ".\keys\ssh\pfsense\pfsense_admin"

function Wait-SSH {
    param (
        [int]$Port,
        [int]$MaxAttempts = 30,
        [int]$DelaySeconds = 5
    )

    Write-Host "-> Attente SSH sur port $Port..."
    for ($i = 0; $i -lt $MaxAttempts; $i++) {
        $res = Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue
        if ($res.TcpTestSucceeded) {
            Write-Host "OK port $Port"
            return
        }
        Start-Sleep -Seconds $DelaySeconds
    }

    throw "Timeout port $Port"
}

function Invoke-PF-SSH {
    param(
        [int]$Port,
        [string]$Command
    )

    & ssh `
      -o StrictHostKeyChecking=no `
      -o UserKnownHostsFile=/dev/null `
      -i $Key `
      -p $Port `
      admin@127.0.0.1 $Command
}

function Invoke-PF-SCP {
    param(
        [int]$Port,
        [string]$Source,
        [string]$Destination
    )

    & scp `
      -o StrictHostKeyChecking=no `
      -o UserKnownHostsFile=/dev/null `
      -i $Key `
      -P $Port `
      $Source `
      ("admin@127.0.0.1:{0}" -f $Destination)
}

# =========================
# PF1
# =========================
Write-Host "=== PF1 ===" -ForegroundColor Cyan
Invoke-PF-SCP 2321 ".\backup\pfsense\pfsense-1-config.xml" "/cf/conf/config.xml"
Invoke-PF-SSH 2321 "/etc/rc.reload_all"
Invoke-PF-SSH 2321 "reboot"

Start-Sleep -Seconds 20
Wait-SSH 2321

# =========================
# PF2
# =========================
Write-Host "=== PF2 ===" -ForegroundColor Cyan
Invoke-PF-SCP 2322 ".\backup\pfsense\pfsense-2-config.xml" "/cf/conf/config.xml"
Invoke-PF-SSH 2322 "/etc/rc.reload_all"
Invoke-PF-SSH 2322 "reboot"

Start-Sleep -Seconds 20
Wait-SSH 2322

# =========================
# PF3
# =========================
Write-Host "=== PF3 ===" -ForegroundColor Cyan
Invoke-PF-SCP 2323 ".\backup\pfsense\pfsense-3-config.xml" "/cf/conf/config.xml"
Invoke-PF-SSH 2323 "/etc/rc.reload_all"
Invoke-PF-SSH 2323 "reboot"

Start-Sleep -Seconds 20
Wait-SSH 2323

Write-Host ""
Write-Host "[OK] Restauration des 3 pfSense terminee." -ForegroundColor Green