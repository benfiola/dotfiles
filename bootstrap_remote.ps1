
function Do-Exit {
    param (
        [int]$ExitCode = 0
    )
    Read-Host -Prompt "Press Enter to exit"
    exit $ExitCode
}

# validate ssh/ssh-keygen exist
cmd /c "where ssh.exe 2>&1" | Out-Null
$SshExists = $?
if(!$SshExists) {
    Write-Host "error: command not found: ssh"
    Do-Exit 1
}
cmd /c "where ssh-keygen.exe 2>&1" | Out-Null
$SshKeygenExists = $?
if(!$SshKeygenExists) {
    Write-Host "error: command not found: ssh-keygen"
    Do-Exit 1
}

# generate private/public key for passwordless ssh
$PEMFile = "$PSScriptRoot\.env.pem"
$PUBFile = "$PSScriptRoot\.env.pub"
$PEMFileExists = Test-Path -LiteralPath $PEMFile
$PUBFileExists = Test-Path -LiteralPath $PUBFile
if(!$PEMFileExists -Or !$PUBFileExists) {
    Write-Host "PEM file exists: $PEMFileExists"
    Write-Host "PUB file exists: $PUBFileExists"
    if($PEMFileExists) {
        Remove-Item "$PEMFile"
    }
    if($PUBFileExists) {
        Remove-Item "$PUBFile"
    }

    Write-Host "generating ssh keys"
    $KeygenCommand = 'ssh-keygen -b 2048 -t rsa -f ' + $PEMFile + ' -q -N "" 2>&1' 
    cmd /c "$KeygenCommand" | Out-Null
    $Success = $?
    if(!$Success) {
        Write-Host "error: failed to generate keypair ($PEMFile, $PUBFile)"
        Do-Exit 1
    }

    Move-Item -Path "$PEMFile.pub" -Destination "$PUBFile"
    Write-Host "generated ssh keys: ($PEMFile, $PUBFile)"
}

# collect target information
$Username = Read-Host -Prompt "Username"
$Hostname = Read-Host -Prompt "Host"

# test whether machine is connectable without a password
$PEMConnectTestCommand = "ssh -i $PEMFile -o StrictHostKeyChecking=no -o PasswordAuthentication=no $Username@$Hostname exit 0"
cmd /c "$PEMConnectTestCommand 2>&1" | Out-Null
$Success = $?
if(!$Success) {
    # install public key if not connectable
    $PUBFileContents = Get-Content "$PUBFile"
    $InstallPublicKeyScript = "$PSScriptRoot/helper_scripts/install_public_key.sh"
    $InstallPublicKeyCommand ="ssh -o StrictHostKeyChecking=no $Username@$Hostname PUBLIC_KEY_DATA='$PUBFileContents' /bin/bash < $InstallPublicKeyScript"
    cmd /c "$InstallPublicKeyCommand"
    $Success = $?
    if(!$Success) {
        Write-Host "error: failed to install public key"
        Do-Exit 1
    }

    # test if machine is connectable after key installation
    cmd /c "$PEMConnectTestCommand 2>&1" | Out-Null
    $Success = $?
    if(!$Success) {
        Write-Host "error: failed to connect to VM with installed key"
        Do-Exit 1
    }
}

# copy remote bootstrap script to machine
$RemoteBootstrapScript = "$PSScriptRoot/bootstrap_local.sh"
$RemoteBootstrapCopyCommand = "scp -i $PEMFile -o StrictHostKeyChecking=no -o PasswordAuthentication=no $RemoteBootstrapScript $Username@${Hostname}:/tmp/script.sh"
cmd /c "$RemoteBootstrapCopyCommand 2>&1" | Out-Null
$Success = $?
if(!$Success) {
    Write-Host "error: failed to copy remote bootstrap script to target"
    Do-Exit 1
}

# run remote bootstrap script on machine
$RemoteBootstrapCommand = "ssh -i $PEMFile -o StrictHostKeyChecking=no -o PasswordAuthentication=no $Username@$Hostname /bin/bash /tmp/script.sh"
cmd /c "$RemoteBootstrapCommand"
$Success = $?
if(!$Success) {
    Write-Host "error: failed to bootstrap target"
    Do-Exit 1
}

Do-Exit
