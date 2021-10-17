. "E:\\keiriroot\\LocalUser\\japansys\\bat\\winrm-session.ps1"

$BAT_DIR_PATH = "E:\keiriroot\LocalUser\japansys\bat"

$cmd = $Args[0]
$host_ip = $Args[1]
$host_user = $Args[2]
$host_password = $Args[3]
$site_name = $Args[4]

try {
    $session = get_session $host_ip $host_user $host_password
    switch ($cmd) {
        "dissolve_site" {
            $result = Invoke-Command -Session $session -FilePath $BAT_DIR_PATH\iis_dissolve_site.ps1 -ArgumentList $site_name
            return $result
        }
        "get_not_bound_ipaddress" {
            $result = Invoke-Command -Session $session -FilePath $BAT_DIR_PATH\iis_get_not_bound_ipaddress.ps1
            return $result
        }
        default {
            return "Invalid command."
        }
    }
    remove_session $session
} catch {
    return $_.Exception.Message
}

return $false