$vm_name = $Args[0]
$vm_user = $Args[1]
$vm_pass = $Args[2]
$vm_action = $Args[3]
$vm_change_action = $Args[4]
$vm_fw = $Args[5]
$password = ConvertTo-SecureString $vm_pass -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList($vm_user, $password)
switch ($vm_action) {
	"change_rdp"{
        if($vm_fw -eq "exist")
        {
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In New)" -Direction Inbound -LocalPort $Args[0] -Protocol TCP -Action allow} -ArgumentList $vm_change_action
        }else{
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{new-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In New)" -Direction Inbound -LocalPort $Args[0] -Protocol TCP -Action allow} -ArgumentList $vm_change_action
        }
              Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In)" -Direction Inbound -Protocol TCP -Action Block}
            return "Complete Add new Port. $vm_name $vm_user $vm_pass $vm_action $vm_change_action"
        }
    "default_rdp"{
        if($vm_fw -eq "exist")
        {
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In New)" -Direction Inbound -Protocol TCP -Action Block}
        }
        Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In)" -Direction Inbound -Protocol TCP -Action Allow}
            return "Complete Add new Port. $vm_name $vm_user $vm_pass $vm_action $vm_change_action"
    }
    "change_rdip"{
        if($vm_fw -eq "exist")
        {
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In New)" -RemoteAddress $Args[0]  -Protocol TCP -Action allow} -ArgumentList $vm_change_action
        }else{
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{new-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In New)" -Direction Inbound -RemoteAddress $Args[0] -Protocol TCP -Action allow} -ArgumentList $vm_change_action
        }
              Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "Remote Desktop - User Mode (TCP-In)" -Direction Inbound -Protocol TCP -Action Block}
            return "Complete Add new Port. $vm_name $vm_user $vm_pass $vm_action $vm_change_action"
        }
    "change_httprdp"{
        if($vm_fw -eq "exist")
        {
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In New)" -Direction Inbound -LocalPort $Args[0] -Protocol TCP -Action allow} -ArgumentList $vm_change_action
        }else{
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{new-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In New)" -Direction Inbound -LocalPort $Args[0] -Protocol TCP -Action allow} -ArgumentList $vm_change_action
        }
              Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In)" -Direction Inbound -Protocol TCP -Action Block}
            return "Complete Add new Port. $vm_name $vm_user $vm_pass $vm_action $vm_change_action"
        }
    "default_httprdp"{
        if($vm_fw -eq "exist")
        {
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In New)" -Direction Inbound -Protocol TCP -Action Block}
        }
        Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In)" -Direction Inbound -Protocol TCP -Action Allow}
            return "Complete Add new Port. $vm_name $vm_user $vm_pass $vm_action $vm_change_action"
    }
    "change_httprdip"{
        if($vm_fw -eq "exist")
        {
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In New)"  -Direction Inbound -RemoteAddress $Args[0] -Protocol TCP -Action allow} -ArgumentList $vm_change_action
        }else{
            Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{new-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In New)" -Direction Inbound -RemoteAddress $Args[0] -Protocol TCP -Action allow} -ArgumentList $vm_change_action
        }
              Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock{set-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In)" -Direction Inbound -Protocol TCP -Action Block}
            return "Complete Add new Port. $vm_name $vm_user $vm_pass $vm_action $vm_change_action"
        }
}