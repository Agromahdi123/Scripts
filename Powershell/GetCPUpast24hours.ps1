$endTime = Get-Date
$startTime = $endTime.AddHours(-24)

$processes = Get-Process | Where-Object { $_.StartTime -ge $startTime -and $_.StartTime -le $endTime } | Sort-Object -Property CPU -Descending | Select-Object -First 5 Name, CPU, Id, Path, Company

$processes | Format-Table -AutoSize Name, CPU, Id, Path, Company
