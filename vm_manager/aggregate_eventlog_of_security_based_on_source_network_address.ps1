$BAT_BASE_PATH = 'E:\\keiriroot\\LocalUser\\japansys\\bat\\'

. "${BAT_BASE_PATH}winrm-session.ps1"
. "${BAT_BASE_PATH}common.ps1"

$output_num = 10
$output_dir_path = "E:\keiriroot\LocalUser\japansys\data\aggregate_eventlog_of_security_based_on_source_network_address\"
if ((Test-Path $output_dir_path) -eq $false) {
    New-Item $output_dir_path -ItemType Directory
}
$output_file_path = $output_dir_path + $(Get-Date -Format 'yyyyMMdd') + '.csv'

$input_file_path = "${BAT_BASE_PATH}aggregate_eventlog_of_security_based_on_source_network_address_targets.csv"
if ((Test-Path $input_file_path) -eq $false) {
    echo $("Not found input file: " + $input_file_path) | Out-File -Force -FilePath $output_file_path -Encoding default
    exit
}

[System.Array] $result = $null
Import-Csv -Path $input_file_path -Delimiter ',' -Encoding Default | ForEach-Object {
    $isvalid = [int]$_.isvalid
    $target_ip = $_.target_ip
    $target_user = $_.target_user
    $target_password = $_.target_password
    
    if ($isvalid -ne 1) {
        return
    }

    try {
        $session = get_session $target_ip $target_user $target_password
        $result += $(Invoke-Command -Session $session -Scriptblock{
            $target_ip = $Args[0]
            $output_num = $Args[1]

            # 集計
            $logs = @{}
            $count = @{}
            Get-EventLog Security | ForEach-Object {
                $instance_id = $_.InstanceId
                $entry_type = $_.EntryType.ToString()
                $source = $_.Source.ToString()
                $category_number = $_.CategoryNumber
                $source_network_address = ''
                $_.Message -split "`n" | ForEach-Object {
                    if ($_ -match "ソース ネットワーク アドレス") {
                        $source_network_address = $($_ -split ":")[1].Trim()
                    }
                }
                
                $key = @($instance_id; $entry_type; $source; $category_number; $source_network_address) -join ','
                $tmp = @{ destination_network_address = $target_ip; instance_id = $instance_id; entry_type = $entry_type; source = $source; category_number = $category_number; source_network_address = $source_network_address; source_network_address_count = 1 }
                if ($logs.ContainsKey($key)) {
                    $logs[$key]['source_network_address_count'] += 1
                    $count[$key] = $logs[$key]['source_network_address_count']
                } else {
                    $logs.Add($key, $tmp)
                    $count.Add($key, 1)
                }
            }
            
            $result = @()
            $count.GetEnumerator() | Sort Value -Descending | ForEach-Object {
                $result += $logs[$_.Key]
                if ($result.Length -eq $output_num) {
                    return
                }
            }
            return $result[0..$($output_num - 1)]
        } -ArgumentList $target_ip, $output_num | ConvertTo-PSObject)
        remove_session $session
    } catch {
        echo $_.Exception
    }
}
$result | Export-Csv -Path $output_file_path -Encoding Default -NoTypeInformation