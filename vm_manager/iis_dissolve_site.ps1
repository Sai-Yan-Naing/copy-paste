function logger ($log, $msg) {
    $date = Get-Date -Format "[yyyy/MM/dd HH:mm:ss]"
    echo "${date} ${msg}" >> $log 2>&1 3>&1
}

try {
    # WEB�T�C�g�ɐݒ肳��Ă��镨���p�X���`�F�b�N
    Import-Module WebAdministration
    $web_site = Get-WebSite -Name $Args[0] -ErrorAction Stop -WarningAction SilentlyContinue
    $physical_path = $web_site.physicalPath
    $physical_path_root_base = [Regex]::Replace($physical_path, "^(.:\\webroot\\LocalUser)\\.+", "`$1")
    if (-not ($physical_path_root_base -match "^.:\\webroot\\LocalUser$")) {
        return "�����p�X�F'${physical_path}'�̃��[�g�f�B���N�g����'^.:\webroot\LocalUser$'�ƈ�v���Ȃ����ߕs���ł��B"
    }

    # ���O��ۑ�����f�B���N�g������уp�X��ݒ�
    $date = Get-Date -Format "yyyyMMdd" -ErrorAction Stop -WarningAction SilentlyContinue
    $log_dir = "${physical_path_root_base}\logs"
    if (-not (Test-Path($log_dir))) {
        New-Item -ItemType Directory -Force -Path $log_dir -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
    }
    $web_site_name = [string]($web_site.Name)
    $log = "${log_dir}\dissolved_${date}_${web_site_name}.log"

    # WEB�T�C�g�����ɉ�񏈗��ς݂����`�F�b�N
    if ($web_site_name -match "^dissolved_\d{8,}_") {
        $msg = "WEB�T�C�g�F'${web_site_name}'�͊��ɉ�񏈗��ς݂ł��B"
        logger $log $msg
        return $msg
    }

    # WEB�f�B���N�g���i���l�[���O�j�����݂��邩���`�F�b�N
    $physical_path_root_base = [Regex]::Replace($web_site.physicalPath, "(.+)\\.+\\.+", "`$1")
    $application_pool_name = [string]($web_site.applicationPool)
    $physical_path_root_old = "${physical_path_root_base}\${application_pool_name}"
    if (-not (Test-Path($physical_path_root_old))) {
        $msg = "WEB�f�B���N�g���i���l�[���O�j�F'${physical_path_root_old}'��������܂���ł����B"
        logger $log $msg
        return $msg
    }
    
    # WEB�f�B���N�g���i���l�[����j�����݂��邩���`�F�b�N
    $date = Get-Date -Format "yyyyMMdd"
    $physical_path_root_new = "${physical_path_root_base}\dissolved_${date}_${application_pool_name}"
    if (Test-Path($physical_path_root_new)) {
        $msg = "WEB�f�B���N�g���i���l�[����j�F'${physical_path_root_new}'�͊��ɑ��݂��Ă��܂��B"
        logger $log $msg
        return $msg
    }

    # �A�v���P�[�V�����v�[���Ƃ�������s���郍�[�J�����[�U�̖��̂�����v���邩���`�F�b�N
    $xml = [xml](c:\Windows\System32\inetsrv\appcmd.exe list apppool "${application_pool_name}" /config:*)
    $user_name = [string]($xml.add.processModel.userName)
    if ($application_pool_name -ne $user_name) {
        $msg = "�A�v���P�[�V�����v�[���F'${application_pool_name}'�ƃ��[�J�����[�U�F'${user_name}'�̖��̂���v���܂���B"
        logger $log $msg
        return $msg
    }

    # WEB�T�C�g���~����B
    $web_site_state = [string]($web_site.State)
    if ($web_site_state -ne 'Stopped') {
        Stop-Website -Name "${web_site_name}" -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "WEB�T�C�g�F'${web_site_name}'�̒�~�𖽗߂��܂����B"
    }

    # �A�v���P�[�V�����v�[�����~����B
    $applicatio_pool_state = [string]((Get-WebAppPoolState "${application_pool_name}").Value)
    if ($applicatio_pool_state -ne 'Stopped') {
        Stop-WebAppPool -Name "${application_pool_name}" -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "�A�v���P�[�V�����v�[���F'${application_pool_name}'�̒�~�𖽗߂��܂����B"
    }

    # ���[�J�����[�U�𖳌�������B
    Disable-LocalUser -Name "${user_name}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "���[�J�����[�U�F'${user_name}'�̖������𖽗߂��܂����B"

    # ���[�J�����[�U�̎��s�v���Z�X���~����B
    Get-Process -IncludeUserName | Where-Object {$_.UserName -match "^*\\${user_name}$"} | ForEach-Object {
        $process_id = $_.Id
        Stop-Process -Id $process_id -Force  -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "���[�J�����[�U�F'${user_name}'�ƕR�Â��v���Z�X�F'${process_id}'�̋����I���𖽗߂��܂����B"
    }

    # ���[�J�����[�U���폜����B
    Remove-LocalUser -Name "${user_name}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "���[�J�����[�U�F'${user_name}'�̍폜�𖽗߂��܂����B"
    
    # �A�v���P�[�V�����v�[�����폜����B
    Remove-WebAppPool -Name "${application_pool_name}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "�A�v���P�[�V�����v�[���F'${application_pool_name}'�̍폜�𖽗߂��܂����B"

    # WEB�T�C�g���폜����B
    Remove-Website -Name "${web_site_name}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "WEB�T�C�g�F'${web_site_name}'�̍폜�𖽗߂��܂����B"

    # applicationHost.config����fastCGI�̐ݒ���폜
    $xpath = "/system.webServer/fastCgi/application[@arguments='-d open_basedir=${physical_path_root_old}']"
    $conf = Get-WebConfiguration -Filter "${xpath}" -ErrorAction Stop -WarningAction SilentlyContinue
    if ([bool] $conf) {
        $ItemXPath = $conf.ItemXPath
        Clear-WebConfiguration -Filter $ItemXPath -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "xpath�F'${xpath}'�̍폜�𖽗߂��܂����B"
    }
    $xpath = "/system.webServer/fastCgi/application[@arguments='-d upload_tmp_dir=${physical_path_root_old}']"
    $conf = Get-WebConfiguration -Filter "${xpath}" -ErrorAction Stop -WarningAction SilentlyContinue
    if ([bool] $conf) {
        $ItemXPath = $conf.ItemXPath
        Clear-WebConfiguration -Filter $ItemXPath -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "xpath�F'${xpath}'�̍폜�𖽗߂��܂����B"
    }
    $xpath = "/system.webServer/fastCgi/application[@arguments='-d open_basedir=${physical_path_root_old} -d upload_tmp_dir=${physical_path_root_old}\tmp']"
    $conf = Get-WebConfiguration -Filter "${xpath}" -ErrorAction Stop -WarningAction SilentlyContinue
    if ([bool] $conf) {
        $ItemXPath = $conf.ItemXPath
        Clear-WebConfiguration -Filter $ItemXPath -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "xpath�F'${xpath}'�̍폜�𖽗߂��܂����B"
    }

    # hosts����IP�A�h���X�ƃh���C���̃}�b�s���O���폜
    $hosts_path = "C:\Windows\System32\drivers\etc\hosts"
    $hosts_path_tmp = "${hosts_path}_tmp"
    Copy-Item -Force -Path $hosts_path -Destination $hosts_path_tmp -ErrorAction Stop -WarningAction SilentlyContinue
    $domains = @()
    $web_site.bindings.Collection | ForEach-Object {
        $bindingInformation = $_.bindingInformation -split ':'
        $domain = $bindingInformation[2]
        $domains += $domain
        $content = (Get-Content $hosts_path_tmp | % { $_ -replace "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}.* +${domain}.*$","" } | Out-String)
        Out-String -InputObject $content | Set-Content $hosts_path_tmp -Force -Encoding Default -ErrorAction Stop -WarningAction SilentlyContinue
    }
    Move-Item -Force $hosts_path_tmp $hosts_path -ErrorAction Stop -WarningAction SilentlyContinue
    $domains = ($domains -join ', ')
    logger $log "'${hosts_path}'����}�b�s���O�F'${domains}'�̍폜�𖽗߂��܂����B"
    
    # WEB�T�C�g�̃f�B���N�g������ύX����B
    Move-Item -Force "${physical_path_root_old}" "${physical_path_root_new}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "'${physical_path_root_old}'��'${physical_path_root_new}'�Ƀ��l�[�����܂����B"
} catch  {
    $msg = $_.Exception.Message
    logger $log $msg
    return $msg
}

return $true