$vm_name = $Args[0]

try {
    # ���z�}�V���̑��݂��`�F�b�N
    $vm = Get-VM -Name $vm_name -ErrorAction Stop -WarningAction SilentlyContinue
    
    # ���z�}�V�������ɉ�񏈗��ς݂����`�F�b�N
    if ($vm.Name -match "^dissolved_\d{8,}_") {
        return ("���z�}�V���F'" + $vm.Name + "'�͊��ɉ�񏈗��ς݂ł��B")
    }
    
    # ���z�}�V����������~
    Stop-VM -Name $vm_name -TurnOff -ErrorAction Stop -WarningAction SilentlyContinue
    
    # ���z�}�V������ύX
    $date = Get-Date -Format "yyyyMMdd"
    $vm_name_new = "dissolved_${date}_" + $vm.Name
    Rename-VM -Name $vm.Name -NewName $vm_name_new -ErrorAction Stop -WarningAction SilentlyContinue
    
    # ���z�}�V���̑��݂��`�F�b�N
    $vm_new = Get-VM -Name $vm_name_new -ErrorAction Stop -WarningAction SilentlyContinue
} catch {
    return $_.Exception.Message
}

return $true