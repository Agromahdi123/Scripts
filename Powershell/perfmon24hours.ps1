# Define the name of the data collector set
$dataCollectorSetName = "CPU Usage"

# Define the path where the data collector set will store its data
$dataCollectorSetPath = "C:\PerfLogs\"

# Define the counters to collect
$counters = "\Processor(_Total)\% Processor Time"

# Create the data collector set
$logman = New-Object -ComObject Logman
$logman.Create($dataCollectorSetName, 1, $counters, $dataCollectorSetPath, 1, 60, "", "")

# Start the data collector set
$logman.Start($dataCollectorSetName)

# Wait for 24 hours
Start-Sleep -Seconds (24 * 60 * 60)

# Stop the data collector set
$logman.Stop($dataCollectorSetName)

# Generate a report
# Note: This requires the "relog" utility, which is included with Windows
$blgFile = Join-Path -Path $dataCollectorSetPath -ChildPath ($dataCollectorSetName + ".blg")
$csvFile = Join-Path -Path $dataCollectorSetPath -ChildPath ($dataCollectorSetName + ".csv")
& 'relog.exe' $blgFile -f CSV -o $csvFile