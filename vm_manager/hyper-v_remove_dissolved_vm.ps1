$CHECKPOINT_REMOVE_LIMIT = 2

function logger ($log, $msg) {
    $date = Get-Date -Format "[yyyy/MM/dd HH:mm:ss]"
    echo "${date} ${msg}" >> $log 2>&1 3>&1
}

$checkpoint_remove_count = 0
try {
    $vms = Get-VM -ErrorAction Stop -WarningAction SilentlyContinue | Where-Object { $_.Name -match "^dissolved_\d{8,}_.*$" -and $_.State -eq "Off" }
    
    foreach ($vm in $vms) {
        # ログを保存するディレクトリおよびパスを設定
        $log_dir = $vm.Path + "\logs"
        if (-not (Test-Path($log_dir))) {
            New-Item -ItemType Directory -Force -Path $log_dir | Out-Null
        }
        $log = $log_dir + "\" + $vm.Name + ".log"

        # 念のために仮想マシン名を確認
        if ($vm.Name -notmatch "^dissolved_\d{8,}_.*$") {
            $msg = "仮想マシン名の接頭辞に'^dissolved_\d{8,}_.*$'が記載されていないので処理を中断します。"
            logger $log $msg
            continue
        }
        
        # 念のために仮想マシンの状態を確認
        if (([string]$vm.State) -ne "Off") {
            $msg = "仮想マシンが停止していないので処理を中断します。"
            logger $log $msg
            continue
        }

        # チェックポイントを一度に大量に削除するとホストの負荷が高くなるのでスキップ
        if ($checkpoint_remove_count -ge $CHECKPOINT_REMOVE_LIMIT) {
            $msg = $vm.Name + " : チェックポイントの削除数が" + $checkpoint_remove_count + "に達したので処理をスキップします。"
            logger $log $msg
            return $true
        }

        # チェックポイントが存在する場合は削除を命令後処理を一旦中断
        if (Get-VMSnapshot -VMName $vm.Name -ErrorAction Stop -WarningAction SilentlyContinue) {
            Remove-VMSnapshot -VMName $vm.Name -ErrorAction Stop -WarningAction SilentlyContinue
            $msg = "Hyper-Vにチェックポイントの削除を命令しました。"
            logger $log $msg
            $checkpoint_remove_count++
            continue
        }

        $vhd_name_prefix = $vm.Name
        foreach($hd in $vm.HardDrives) {
            if (-not (Test-Path($hd.Path))) {
                continue
            }

            $vhd_dir = [Regex]::Replace($hd.Path, "(.+)\\.*", "`$1")
            if (-not (Test-Path($vhd_dir))) {
                $msg = "'${vhd_dir}'が見つかりませんでした。"
                logger $log $msg
                return $msg
            }

            $vhd_name = [Regex]::Replace($hd.Path,".*\\","")
            $new_vhd_path = "${vhd_dir}\${vhd_name_prefix}_${vhd_name}"
            Move-Item $hd.Path $new_vhd_path -ErrorAction Stop -WarningAction SilentlyContinue
            $msg = "'" + $hd.Path + "'を'" + $new_vhd_path + "'にリネームしました。"
            logger $log $msg
        }

        Remove-VM -Name $vm.Name -Force -ErrorAction Stop -WarningAction SilentlyContinue
        $msg = "Hyper-Vに仮想マシンの削除を命令しました。"
        logger $log $msg
    }
} catch {
    $msg = $_.Exception.Message
    logger $log $msg
    return $msg
}

return $true