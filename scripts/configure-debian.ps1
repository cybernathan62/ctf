$ErrorActionPreference = "Stop"

$projectPath = Split-Path -Parent $PSScriptRoot
Set-Location $projectPath

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "   CONFIGURATION DEBIAN - START    " -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

$bashScript = @'
#!/usr/bin/env bash
set -euo pipefail

wait_runtime_ping() {
  local host="$1"
  local inventory="inventories/lab/hosts-runtime.yml"

  echo "--- Attente runtime pour ${host} ---"
  for i in $(seq 1 12); do
    if ansible "${host}" -i "${inventory}" -m ping >/dev/null 2>&1; then
      ansible "${host}" -i "${inventory}" -m ping
      return 0
    fi
    echo "Tentative ${i}/12 echouee pour ${host}, attente 5s..."
    sleep 5
  done

  echo "ERREUR: ${host} reste injoignable sur l'inventory runtime"
  ansible "${host}" -i "${inventory}" -m ping || true
  return 1
}

echo '--- Verification inventory bootstrap ---'
ansible-inventory -i inventories/lab/hosts-bootstrap.yml --graph

echo '--- Verification inventory runtime ---'
ansible-inventory -i inventories/lab/hosts-runtime.yml --graph

echo '=== 1. Bastion ==='
ansible bastion -i inventories/lab/hosts-bootstrap.yml -m ping
ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/bastion-cutover.yml
wait_runtime_ping bastion

echo '=== 2. DMZ ==='
ansible dmz -i inventories/lab/hosts-bootstrap.yml -m ping
ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/dmz-cutover.yml
wait_runtime_ping dmz

echo '=== 3. Zabbix ==='
ansible zabbix -i inventories/lab/hosts-bootstrap.yml -m ping
ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/zabbix-cutover.yml
wait_runtime_ping zabbix

echo '=== 4. Wazuh ==='
ansible wazuh -i inventories/lab/hosts-bootstrap.yml -m ping
ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/wazuh-cutover.yml
wait_runtime_ping wazuh

echo '=== 5. DB Server ==='
ansible db-server -i inventories/lab/hosts-bootstrap.yml -m ping
ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/db-server-cutover.yml
wait_runtime_ping db-server

echo '--- Verification finale Debian ---'
ansible debian -i inventories/lab/hosts-runtime.yml -m ping
'@

# Normaliser en LF
$bashScript = $bashScript -replace "`r`n", "`n"
$bashScript = $bashScript -replace "`r", "`n"

$tempScript = Join-Path $projectPath "tmp\configure-debian-runtime.sh"
New-Item -ItemType Directory -Force -Path (Join-Path $projectPath "tmp") | Out-Null
[System.IO.File]::WriteAllText($tempScript, $bashScript, (New-Object System.Text.UTF8Encoding($false)))

docker run --rm -t `
  -v "${projectPath}:/lab" `
  -w /lab/ansible `
  -e ANSIBLE_CONFIG=/lab/ansible/ansible.cfg `
  ctf-ansible /bin/bash /lab/tmp/configure-debian-runtime.sh

if ($LASTEXITCODE -ne 0) {
    throw "Echec de la configuration Debian"
}

Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host " CONFIGURATION DEBIAN - TERMINEE   " -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green