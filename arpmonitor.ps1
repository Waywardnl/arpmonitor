# Configuratie
$MacAddressFile = "C:\temp\MacAddresses.txt"
$LogFile = "C:\temp\MacAddressLog.txt"
$ThresholdPercentage = 30

# Functie voor logging
function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] $Message"
    Write-Output $LogMessage | Out-File -Append -FilePath $LogFile
    Write-Host $LogMessage
}

# Functie om unieke MAC-adressen te verkrijgen
function Get-MacAddresses {
    arp -a | ForEach-Object {
        if ($_ -match "([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}") {
            $matches[0] -replace "[:-]", "-"  # Uniformeer MAC-adressen
        }
    } | Sort-Object -Unique
}

# Actie bij detectie van veranderingen
function OnChangeDetected {
    Write-Log "30% of MAC addresses have changed or disappeared!"
    # Voeg hier een extra actie toe, zoals een e-mailnotificatie of alarm.
}

# Logging start
Write-Log "Starting MAC address monitoring script."

# Huidige MAC-adressen ophalen
$CurrentMacAddresses = Get-MacAddresses
Write-Log "Current MAC addresses: $($CurrentMacAddresses -join ', ')"

# Controlebestand inladen of aanmaken
if (Test-Path $MacAddressFile) {
    $PreviousMacAddresses = Get-Content $MacAddressFile
    Write-Log "Previous MAC addresses loaded."
} else {
    $PreviousMacAddresses = @()
    $CurrentMacAddresses | Out-File $MacAddressFile
    Write-Log "No previous MAC addresses found. Created a new reference file."
}

# Vergelijken van de MAC-adressen
$RemovedMacs = $PreviousMacAddresses | Where-Object { $_ -notin $CurrentMacAddresses }
$NewMacs = $CurrentMacAddresses | Where-Object { $_ -notin $PreviousMacAddresses }

Write-Log "Removed MACs: $($RemovedMacs -join ', ')"
Write-Log "New MACs: $($NewMacs -join ', ')"

# Detecteren van wijzigingen
$TotalMacs = [math]::Max($PreviousMacAddresses.Count, $CurrentMacAddresses.Count)
if ($TotalMacs -eq 0) {
    Write-Log "No MAC addresses to compare. Exiting script."
    exit
}

$ChangedPercentage = (($RemovedMacs.Count + $NewMacs.Count) / $TotalMacs) * 100
Write-Log "Changed percentage: $ChangedPercentage%"

if ($ChangedPercentage -ge $ThresholdPercentage) {
    OnChangeDetected
} else {
    Write-Log "Change percentage below threshold. No action taken."
}

# Huidige MAC-adressen opslaan
$CurrentMacAddresses | Out-File $MacAddressFile
Write-Log "Updated MAC addresses saved."
Write-Log "Script execution completed."
