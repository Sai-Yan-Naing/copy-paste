try {
    Import-Module WebAdministration

    $bound_ipaddress = @()
    Get-WebBinding -ErrorAction Stop -WarningAction SilentlyContinue | ForEach-Object {
        $bound_ipaddress += $_.bindingInformation.split(':')[0]
    }
    $bound_ipaddress = $bound_ipaddress | Sort-Object | Get-Unique
    
    $not_bound_ipaddress = @()
    Get-WmiObject -Class Win32_NetworkAdapterConfiguration | ForEach-Object {
        foreach ($ipaddres in $_.IPAddress) {
            if (-not $bound_ipaddress.Contains($ipaddres)) {
                $not_bound_ipaddress += $ipaddres
            }
        }
    }
    $not_bound_ipaddress = $not_bound_ipaddress | Sort-Object | Get-Unique

    return $not_bound_ipaddress
} catch  {
    $msg = $_.Exception.Message
    return $msg
}
