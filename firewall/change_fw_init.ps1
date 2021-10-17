# if($Args[1] -eq "change_rdp"){
#     # write-host $Args[0]
#     set-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In)" -Direction Inbound -LocalPort $Args[0] -Protocol TCP -Action allow
# }elseif( $Args[1] -eq "change_rdip" ){
#     Set-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In)" -RemoteAddress $Args[0]
# }elseif( $Args[1] -eq "change_webrdp" ){
#     set-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In)" -Direction Inbound -LocalPort $Args[0] -Protocol TCP -Action allow
# }elseif( $Args[1] -eq "change_webrdip" ){
#     Set-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In)" -RemoteAddress $Args[0]
# }

. "E:\scripts\vm_manager\winrm-session.ps1"

# $BAT_DIR_PATH = "E:\scripts\vm_manager"
$cmd = $Args[0]
$host_ip = $Args[1]
$host_user = $Args[2]
$host_password = $Args[3]
$vm_name = $Args[4]
$vm_user = $Args[5]
$vm_pass = $Args[6]
$vm_action = $Args[7]
$vm_change_action  = $Args[8]
$vm_fw = $Args[9]
$ip = $Args[10]
$gateway = $Args[11]

try {
    $session = get_session $host_ip $host_user $host_password
    switch ($cmd) {
        "firewall"{
            Invoke-Command -Session $session -Scriptblock{C:\vm_manager\firewall.ps1 $Args[0] $Args[1] $Args[2] $Args[3] $Args[4] $Args[5]} -ArgumentList $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw
            return "Complete Add new Port $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw"
        }
        "change_pass"{
            Invoke-Command -Session $session -Scriptblock{C:\vm_manager\change_pass.ps1 $Args[0] $Args[1] $Args[2] $Args[3] $Args[4] $Args[5]} -ArgumentList $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw
            return "Complete Add new Port $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw"
        }
        "install_sqlserver"{
            Invoke-Command -Session $session -Scriptblock{C:\vm_manager\install_sqlserver.ps1 $Args[0] $Args[1] $Args[2] $Args[3] $Args[4] $Args[5]} -ArgumentList $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw
            return "Complete Add new Port $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw"
        }
        "reinitializevm"{
            $result = Invoke-Command -Session $session -Scriptblock{C:\vm_manager\reinitializevm.ps1 $Args[0] $Args[1] $Args[2] $Args[3] $Args[4] $Args[5] $Args[6] $Args[7]} -ArgumentList $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw, $ip, $gateway
         return "success"
        }
        "changeplan"{
            $result = Invoke-Command -Session $session -Scriptblock{C:\vm_manager\changeplan.ps1 $Args[0] $Args[1] $Args[2] $Args[3] $Args[4] $Args[5]} -ArgumentList $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw
         return "success"
        }
        "loadstatus"{
            $result = Invoke-Command -Session $session -Scriptblock{C:\vm_manager\loadstatus.ps1 $Args[0] $Args[1] $Args[2] $Args[3] $Args[4] $Args[5]} -ArgumentList $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw
            
             return $result
         
        }
        "iisinstall"{
            $result = Invoke-Command -Session $session -Scriptblock{C:\vm_manager\iisinstall.ps1 $Args[0] $Args[1] $Args[2] $Args[3] $Args[4] $Args[5]} -ArgumentList $vm_name, $vm_user, $vm_pass, $vm_action, $vm_change_action, $vm_fw
            
             return $result
         
        }default {
            return "Invalid command."
        }
    }
    remove_session $session
} catch {
    return $_.Exception
}
return $false

