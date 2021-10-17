# 連想配列をPSObjectに変換する。
function ConvertTo-PSObject {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.Collections.Hashtable[]]$hash,
        [switch]$recurse
    )
    process {
        foreach ($hashElem in $hash) {
            $result = New-Object PSObject
            foreach ($key in $hashElem.keys) {
                if ($hashElem[$key] -as [System.Collections.Hashtable[]] -and $recurse) {
                    $result|Add-Member -MemberType "NoteProperty" -Name $key -Value (ConvertTo-PSObject $hashElem[$key] -recurse)
                } elseif($hashElem[$key] -is [scriptblock]) {
                    $result|Add-Member -MemberType "ScriptMethod" -Name $key -Value $hashElem[$key]
                } else {
                    $result|Add-Member -MemberType "NoteProperty" -Name $key -Value $hashElem[$key]
                }
            }
            return $result
        }
    }
}