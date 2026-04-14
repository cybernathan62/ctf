param(
    [switch]$SkipVmDeploy,
    [switch]$SkipPfSenseRestore,
    [switch]$SkipDebianCutover,
    [switch]$SkipRuntimePing
)

$ErrorActionPreference = "Stop"

$projectRoot   = Split-Path -Parent $PSScriptRoot
$restoreScript = Join-Path $PSScriptRoot "restore-pfsense.ps1"

Set-Location $projectRoot

$ansibleImage = "ctf-ansible:latest"

$bootstrapInventory = Join-Path $projectRoot "ansible\inventories\lab\hosts-bootstrap.yml"
$runtimeInventory   = Join-Path $projectRoot "ansible\inventories\lab\hosts-runtime.yml"
$ansibleCfg         = Join-Path $projectRoot "ansible\ansible.cfg"

$cutoverPlaybooks = @(
    "playbooks/bastion-cutover.yml",
    "playbooks/zabbix-cutover.yml",
    "playbooks/db-server-cutover.yml",
    "playbooks/wazuh-cutover.yml",
    "playbooks/dmz-site.yml"
)

$bootstrapDebianHosts = "bastion:dmz:zabbix:db-server:wazuh"
$runtimeDebianHosts   = "bastion:dmz:zabbix:db-server:wazuh"

$allVMs = @(
    "pfsense-1",
    "pfsense-2",
    "pfsense-3",
    "bastion",
    "dmz",
    "zabbix",
    "wazuh",
    "db-server"
)

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan

    & $Action
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        throw "Commande introuvable : $CommandName"
    }
}

function Start-DockerDesktopIfNeeded {
    param(
        [int]$TimeoutSeconds = 180
    )

    Write-Host "[INFO] Vérification de Docker..." -ForegroundColor Cyan

    try {
        docker info *> $null
        Write-Host "[OK] Docker est déjà prêt." -ForegroundColor Green
        return
    }
    catch {
        Write-Host "[WARN] Docker ne répond pas. Tentative de démarrage..." -ForegroundColor Yellow
    }

    try {
        wsl --shutdown *> $null
    }
    catch {
        Write-Host "[WARN] Impossible d'arrêter WSL proprement, on continue..." -ForegroundColor Yellow
    }

    $dockerDesktopPaths = @(
        "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
        "$Env:LocalAppData\Programs\Docker\Docker\Docker Desktop.exe",
        "$Env:LocalAppData\Docker\Docker Desktop.exe"
    )

    $dockerStarted = $false

    foreach ($path in $dockerDesktopPaths) {
        if (Test-Path $path) {
            Write-Host "[INFO] Lancement de Docker Desktop : $path" -ForegroundColor Cyan
            Start-Process -FilePath $path
            $dockerStarted = $true
            break
        }
    }

    if (-not $dockerStarted) {
        throw "Docker Desktop.exe introuvable."
    }

    $start = Get-Date
    do {
        Start-Sleep -Seconds 5
        try {
            docker info *> $null
            Write-Host "[OK] Docker est prêt." -ForegroundColor Green
            return
        }
        catch {
            Write-Host "[INFO] En attente du moteur Docker..." -ForegroundColor Yellow
        }
    } while (((Get-Date) - $start).TotalSeconds -lt $TimeoutSeconds)

    throw "Docker Desktop a été lancé, mais le moteur Docker n'est pas prêt après $TimeoutSeconds secondes."
}

function Test-DockerImage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImageName
    )

    docker image inspect $ImageName *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Image Docker introuvable : $ImageName"
    }
}

function Get-RunningVmNames {
    $lines = & VBoxManage list runningvms 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $lines) {
        return @()
    }

    $names = @()
    foreach ($line in $lines) {
        if ($line -match '^"([^"]+)"\s+\{') {
            $names += $matches[1]
        }
    }

    return $names
}

function Start-VagrantVMsIfNeeded {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$VMNames
    )

    $running = Get-RunningVmNames

    foreach ($vm in $VMNames) {
        if ($running -contains $vm) {
            Write-Host "[OK] VM déjà démarrée : $vm" -ForegroundColor Green
            continue
        }

        Write-Host "[INFO] Démarrage VM : $vm" -ForegroundColor Cyan
        vagrant up $vm

        if ($LASTEXITCODE -ne 0) {
            throw "Echec démarrage VM : $vm (code=$LASTEXITCODE)"
        }
    }
}

function Invoke-AnsibleInDocker {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,

        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    Write-Host ""
    Write-Host "[INFO] $StepName" -ForegroundColor Cyan

    $mountPath = (Resolve-Path $projectRoot).Path -replace '\\', '/'

    docker run --rm `
        -v "${mountPath}:/lab" `
        -w /lab/ansible `
        -e ANSIBLE_CONFIG=/lab/ansible/ansible.cfg `
        -e ANSIBLE_HOST_KEY_CHECKING=False `
        $ansibleImage /bin/bash -lc $Command

    if ($LASTEXITCODE -ne 0) {
        throw "Echec étape Docker/Ansible : $StepName (code=$LASTEXITCODE)"
    }
}

function Test-PathOrThrow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    if (-not (Test-Path $PathValue)) {
        throw "Fichier introuvable : $PathValue"
    }
}

try {
    Invoke-Step -Title "ETAPE 1/6 - VERIFICATIONS" -Action {
        Test-CommandExists -CommandName "vagrant"
        Test-CommandExists -CommandName "docker"
        Test-CommandExists -CommandName "VBoxManage"

        Test-PathOrThrow -PathValue $restoreScript
        Test-PathOrThrow -PathValue $bootstrapInventory
        Test-PathOrThrow -PathValue $runtimeInventory
        Test-PathOrThrow -PathValue $ansibleCfg

        foreach ($playbook in $cutoverPlaybooks) {
            Test-PathOrThrow -PathValue (Join-Path $projectRoot "ansible\$playbook")
        }

        Start-DockerDesktopIfNeeded
        Test-DockerImage -ImageName $ansibleImage

        Write-Host "[OK] Vérifications terminées." -ForegroundColor Green
    }

    if (-not $SkipVmDeploy) {
        Invoke-Step -Title "ETAPE 2/6 - DEPLOIEMENT / DEMARRAGE DES VM" -Action {
            Start-VagrantVMsIfNeeded -VMNames $allVMs
            vagrant status
        }
    }

    Invoke-Step -Title "ETAPE 3/6 - VALIDATION ANSIBLE BOOTSTRAP SUR DOCKER" -Action {
        Invoke-AnsibleInDocker `
            -StepName "Ping bootstrap Debian" `
            -Command "ansible '$bootstrapDebianHosts' -i inventories/lab/hosts-bootstrap.yml -m ping -vv"

        Invoke-AnsibleInDocker `
            -StepName "Ping bootstrap pfSense" `
            -Command "ansible pfsense -i inventories/lab/hosts-bootstrap.yml -m ping -vv"
    }

    if (-not $SkipPfSenseRestore) {
        Invoke-Step -Title "ETAPE 4/6 - RESTORE PFSENSE" -Action {
            & $restoreScript

            if (-not $?) {
                throw "Le script restore-pfsense.ps1 a signalé un échec."
            }

            Write-Host "[OK] Restore pfSense terminé." -ForegroundColor Green
        }
    }

    if (-not $SkipDebianCutover) {
        Invoke-Step -Title "ETAPE 5/6 - CUTOVER DEBIAN + DMZ SITE" -Action {
            Invoke-AnsibleInDocker `
                -StepName "Cutover bastion" `
                -Command "ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/bastion-cutover.yml -vv"

            Invoke-AnsibleInDocker `
                -StepName "Cutover zabbix" `
                -Command "ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/zabbix-cutover.yml -vv"

            Invoke-AnsibleInDocker `
                -StepName "Cutover db-server" `
                -Command "ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/db-server-cutover.yml -vv"

            Invoke-AnsibleInDocker `
                -StepName "Cutover wazuh" `
                -Command "ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/wazuh-cutover.yml -vv"

            Invoke-AnsibleInDocker `
                -StepName "Déploiement site DMZ" `
                -Command "ansible-playbook -i inventories/lab/hosts-bootstrap.yml playbooks/dmz-site.yml -vv"
        }
    }

    if (-not $SkipRuntimePing) {
        Invoke-Step -Title "ETAPE 6/6 - VALIDATION RUNTIME" -Action {
            Invoke-AnsibleInDocker `
                -StepName "Ping runtime pfSense" `
                -Command "ansible pfsense -i inventories/lab/hosts-runtime.yml -m ping -vv"

            Invoke-AnsibleInDocker `
                -StepName "Ping runtime Debian" `
                -Command "ansible '$runtimeDebianHosts' -i inventories/lab/hosts-runtime.yml -m ping -vv"
        }
    }

    Write-Host ""
    Write-Host "[OK] Start-lab terminé." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "[ERREUR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}