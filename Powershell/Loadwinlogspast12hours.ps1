# Get the current date and time
$endTime = Get-Date

# Subtract 12 hours to get the start time
$startTime = $endTime.AddHours(-12)

# Define the log names to search
$logNames = "System", "Application", "Security"

# Get the events
$events = Get-WinEvent -FilterHashtable @{LogName=$logNames; StartTime=$startTime; EndTime=$endTime}

# Output the events
$events | Format-Table -AutoSize TimeCreated, Id, ProviderName, Message