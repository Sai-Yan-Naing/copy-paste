
$arg1 = $Args[0]
$arg2 = $Args[1]
$arg3 = $Args[2]
$arg4 = $Args[3]
$arg5 = $Args[4]
$arg6 = $Args[5]
$arg7 = $Args[6]
$arg8 = $Args[7]
$arg9 = $Args[8]
$arg10 = $Args[9]
$arg11 = $Args[10]
$arg12 = $Args[11]

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""E:\scripts\firewall\change_fw_con.ps1"" $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12' -Verb RunAs}"
#write-host $arg10
