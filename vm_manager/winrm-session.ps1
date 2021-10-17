function get_session($server=$null, $user=$null, $passwd=$null, $port=5985) {
    try {
        $secure_string = ConvertTo-SecureString $passwd -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PsCredential($user, $secure_string)
        return New-PSSession -ComputerName $server -Credential $credential -Port $port
    } catch {
        return $null
    }
}

function remove_session($session=$null) {
    try {
        return Remove-PSSession -Session $session
    } catch {
        return $null
    }
}