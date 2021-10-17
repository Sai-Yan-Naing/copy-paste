function logger ($log, $msg) {
    $date = Get-Date -Format "[yyyy/MM/dd HH:mm:ss]"
    echo "${date} ${msg}" >> $log 2>&1 3>&1
}

try {
    # WEBサイトに設定されている物理パスをチェック
    Import-Module WebAdministration
    $web_site = Get-WebSite -Name $Args[0] -ErrorAction Stop -WarningAction SilentlyContinue
    $physical_path = $web_site.physicalPath
    $physical_path_root_base = [Regex]::Replace($physical_path, "^(.:\\webroot\\LocalUser)\\.+", "`$1")
    if (-not ($physical_path_root_base -match "^.:\\webroot\\LocalUser$")) {
        return "物理パス：'${physical_path}'のルートディレクトリが'^.:\webroot\LocalUser$'と一致しないため不正です。"
    }

    # ログを保存するディレクトリおよびパスを設定
    $date = Get-Date -Format "yyyyMMdd" -ErrorAction Stop -WarningAction SilentlyContinue
    $log_dir = "${physical_path_root_base}\logs"
    if (-not (Test-Path($log_dir))) {
        New-Item -ItemType Directory -Force -Path $log_dir -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
    }
    $web_site_name = [string]($web_site.Name)
    $log = "${log_dir}\dissolved_${date}_${web_site_name}.log"

    # WEBサイトが既に解約処理済みかをチェック
    if ($web_site_name -match "^dissolved_\d{8,}_") {
        $msg = "WEBサイト：'${web_site_name}'は既に解約処理済みです。"
        logger $log $msg
        return $msg
    }

    # WEBディレクトリ（リネーム前）が存在するかをチェック
    $physical_path_root_base = [Regex]::Replace($web_site.physicalPath, "(.+)\\.+\\.+", "`$1")
    $application_pool_name = [string]($web_site.applicationPool)
    $physical_path_root_old = "${physical_path_root_base}\${application_pool_name}"
    if (-not (Test-Path($physical_path_root_old))) {
        $msg = "WEBディレクトリ（リネーム前）：'${physical_path_root_old}'が見つかりませんでした。"
        logger $log $msg
        return $msg
    }
    
    # WEBディレクトリ（リネーム後）が存在するかをチェック
    $date = Get-Date -Format "yyyyMMdd"
    $physical_path_root_new = "${physical_path_root_base}\dissolved_${date}_${application_pool_name}"
    if (Test-Path($physical_path_root_new)) {
        $msg = "WEBディレクトリ（リネーム後）：'${physical_path_root_new}'は既に存在しています。"
        logger $log $msg
        return $msg
    }

    # アプリケーションプールとそれを実行するローカルユーザの名称をが一致するかをチェック
    $xml = [xml](c:\Windows\System32\inetsrv\appcmd.exe list apppool "${application_pool_name}" /config:*)
    $user_name = [string]($xml.add.processModel.userName)
    if ($application_pool_name -ne $user_name) {
        $msg = "アプリケーションプール：'${application_pool_name}'とローカルユーザ：'${user_name}'の名称が一致しません。"
        logger $log $msg
        return $msg
    }

    # WEBサイトを停止する。
    $web_site_state = [string]($web_site.State)
    if ($web_site_state -ne 'Stopped') {
        Stop-Website -Name "${web_site_name}" -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "WEBサイト：'${web_site_name}'の停止を命令しました。"
    }

    # アプリケーションプールを停止する。
    $applicatio_pool_state = [string]((Get-WebAppPoolState "${application_pool_name}").Value)
    if ($applicatio_pool_state -ne 'Stopped') {
        Stop-WebAppPool -Name "${application_pool_name}" -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "アプリケーションプール：'${application_pool_name}'の停止を命令しました。"
    }

    # ローカルユーザを無効化する。
    Disable-LocalUser -Name "${user_name}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "ローカルユーザ：'${user_name}'の無効化を命令しました。"

    # ローカルユーザの実行プロセスを停止する。
    Get-Process -IncludeUserName | Where-Object {$_.UserName -match "^*\\${user_name}$"} | ForEach-Object {
        $process_id = $_.Id
        Stop-Process -Id $process_id -Force  -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "ローカルユーザ：'${user_name}'と紐づくプロセス：'${process_id}'の強制終了を命令しました。"
    }

    # ローカルユーザを削除する。
    Remove-LocalUser -Name "${user_name}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "ローカルユーザ：'${user_name}'の削除を命令しました。"
    
    # アプリケーションプールを削除する。
    Remove-WebAppPool -Name "${application_pool_name}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "アプリケーションプール：'${application_pool_name}'の削除を命令しました。"

    # WEBサイトを削除する。
    Remove-Website -Name "${web_site_name}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "WEBサイト：'${web_site_name}'の削除を命令しました。"

    # applicationHost.configからfastCGIの設定を削除
    $xpath = "/system.webServer/fastCgi/application[@arguments='-d open_basedir=${physical_path_root_old}']"
    $conf = Get-WebConfiguration -Filter "${xpath}" -ErrorAction Stop -WarningAction SilentlyContinue
    if ([bool] $conf) {
        $ItemXPath = $conf.ItemXPath
        Clear-WebConfiguration -Filter $ItemXPath -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "xpath：'${xpath}'の削除を命令しました。"
    }
    $xpath = "/system.webServer/fastCgi/application[@arguments='-d upload_tmp_dir=${physical_path_root_old}']"
    $conf = Get-WebConfiguration -Filter "${xpath}" -ErrorAction Stop -WarningAction SilentlyContinue
    if ([bool] $conf) {
        $ItemXPath = $conf.ItemXPath
        Clear-WebConfiguration -Filter $ItemXPath -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "xpath：'${xpath}'の削除を命令しました。"
    }
    $xpath = "/system.webServer/fastCgi/application[@arguments='-d open_basedir=${physical_path_root_old} -d upload_tmp_dir=${physical_path_root_old}\tmp']"
    $conf = Get-WebConfiguration -Filter "${xpath}" -ErrorAction Stop -WarningAction SilentlyContinue
    if ([bool] $conf) {
        $ItemXPath = $conf.ItemXPath
        Clear-WebConfiguration -Filter $ItemXPath -ErrorAction Stop -WarningAction SilentlyContinue
        logger $log "xpath：'${xpath}'の削除を命令しました。"
    }

    # hostsからIPアドレスとドメインのマッピングを削除
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
    logger $log "'${hosts_path}'からマッピング：'${domains}'の削除を命令しました。"
    
    # WEBサイトのディレクトリ名を変更する。
    Move-Item -Force "${physical_path_root_old}" "${physical_path_root_new}" -ErrorAction Stop -WarningAction SilentlyContinue
    logger $log "'${physical_path_root_old}'を'${physical_path_root_new}'にリネームしました。"
} catch  {
    $msg = $_.Exception.Message
    logger $log $msg
    return $msg
}

return $true