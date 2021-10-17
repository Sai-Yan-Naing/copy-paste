$vm_name = $Args[0]

try {
    # 仮想マシンの存在をチェック
    $vm = Get-VM -Name $vm_name -ErrorAction Stop -WarningAction SilentlyContinue
    
    # 仮想マシンが既に解約処理済みかをチェック
    if ($vm.Name -match "^dissolved_\d{8,}_") {
        return ("仮想マシン：'" + $vm.Name + "'は既に解約処理済みです。")
    }
    
    # 仮想マシンを強制停止
    Stop-VM -Name $vm_name -TurnOff -ErrorAction Stop -WarningAction SilentlyContinue
    
    # 仮想マシン名を変更
    $date = Get-Date -Format "yyyyMMdd"
    $vm_name_new = "dissolved_${date}_" + $vm.Name
    Rename-VM -Name $vm.Name -NewName $vm_name_new -ErrorAction Stop -WarningAction SilentlyContinue
    
    # 仮想マシンの存在をチェック
    $vm_new = Get-VM -Name $vm_name_new -ErrorAction Stop -WarningAction SilentlyContinue
} catch {
    return $_.Exception.Message
}

return $true