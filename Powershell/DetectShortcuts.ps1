$files = @(
    "C:\Users\Public\Desktop\Concur.lnk"
    "C:\Users\Public\Desktop\NewEvolv.lnk"
    "C:\Users\Public\Desktop\UltiPro.lnk"
    "C:\Users\Public\Desktop\Word.lnk"
)
$badcount = 0
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host ("{0} was found" -f $file)
    }
    else {
        Write-Host ("{0} was not found" -f $file)
        $badcount++
    }
}
If ($badcount -gt 0) {
    Write-Host ("Not all Desktop Shortcut files were found...")
    exit 1
}
else {
    Write-Host ("All Desktop Shortcut files were found...")
    exit 0
}