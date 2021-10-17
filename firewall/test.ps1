. "E:\scripts\vm_manager\winrm-session.ps1"

$BAT_DIR_PATH = "E:\scripts\vm_manager"
$vm_name = "20210820VPS"
Invoke-Command -Session $session -Scriptblock{Start-VM -Name $Args[0]} -ArgumentList $vm_name