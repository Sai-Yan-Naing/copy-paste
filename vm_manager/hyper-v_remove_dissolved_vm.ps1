$CHECKPOINT_REMOVE_LIMIT = 2

function logger ($log, $msg) {
    $date = Get-Date -Format "[yyyy/MM/dd HH:mm:ss]"
    echo "${date} ${msg}" >> $log 2>&1 3>&1
}

$checkpoint_remove_count = 0
try {
    $vms = Get-VM -ErrorAction Stop -WarningAction SilentlyContinue | Where-Object { $_.Name -match "^dissolved_\d{8,}_.*$" -and $_.State -eq "Off" }
    
    foreach ($vm in $vms) {
        # ���O��ۑ�����f�B���N�g������уp�X��ݒ�
        $log_dir = $vm.Path + "\logs"
        if (-not (Test-Path($log_dir))) {
            New-Item -ItemType Directory -Force -Path $log_dir | Out-Null
        }
        $log = $log_dir + "\" + $vm.Name + ".log"

        # �O�̂��߂ɉ��z�}�V�������m�F
        if ($vm.Name -notmatch "^dissolved_\d{8,}_.*$") {
            $msg = "���z�}�V�����̐ړ�����'^dissolved_\d{8,}_.*$'���L�ڂ���Ă��Ȃ��̂ŏ����𒆒f���܂��B"
            logger $log $msg
            continue
        }
        
        # �O�̂��߂ɉ��z�}�V���̏�Ԃ��m�F
        if (([string]$vm.State) -ne "Off") {
            $msg = "���z�}�V������~���Ă��Ȃ��̂ŏ����𒆒f���܂��B"
            logger $log $msg
            continue
        }

        # �`�F�b�N�|�C���g����x�ɑ�ʂɍ폜����ƃz�X�g�̕��ׂ������Ȃ�̂ŃX�L�b�v
        if ($checkpoint_remove_count -ge $CHECKPOINT_REMOVE_LIMIT) {
            $msg = $vm.Name + " : �`�F�b�N�|�C���g�̍폜����" + $checkpoint_remove_count + "�ɒB�����̂ŏ������X�L�b�v���܂��B"
            logger $log $msg
            return $true
        }

        # �`�F�b�N�|�C���g�����݂���ꍇ�͍폜�𖽗ߌ㏈������U���f
        if (Get-VMSnapshot -VMName $vm.Name -ErrorAction Stop -WarningAction SilentlyContinue) {
            Remove-VMSnapshot -VMName $vm.Name -ErrorAction Stop -WarningAction SilentlyContinue
            $msg = "Hyper-V�Ƀ`�F�b�N�|�C���g�̍폜�𖽗߂��܂����B"
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
                $msg = "'${vhd_dir}'��������܂���ł����B"
                logger $log $msg
                return $msg
            }

            $vhd_name = [Regex]::Replace($hd.Path,".*\\","")
            $new_vhd_path = "${vhd_dir}\${vhd_name_prefix}_${vhd_name}"
            Move-Item $hd.Path $new_vhd_path -ErrorAction Stop -WarningAction SilentlyContinue
            $msg = "'" + $hd.Path + "'��'" + $new_vhd_path + "'�Ƀ��l�[�����܂����B"
            logger $log $msg
        }

        Remove-VM -Name $vm.Name -Force -ErrorAction Stop -WarningAction SilentlyContinue
        $msg = "Hyper-V�ɉ��z�}�V���̍폜�𖽗߂��܂����B"
        logger $log $msg
    }
} catch {
    $msg = $_.Exception.Message
    logger $log $msg
    return $msg
}

return $true