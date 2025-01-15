param (
    [int]$ThresholdPercentage = 30,               # Wijzigingspercentage
    [string]$LogFile = "C:\temp\MacAddressLog.txt", # Locatie van het logbestand
    [int]$MaxInstances = 1,                       # Maximum aantal scriptinstanties
    [int]$LogFileSizeThresholdKB = 1024,          # Maximale grootte van het logbestand in KB
    [int]$MaxZipFiles = 5,                        # Maximum aantal zip-bestanden
    [string]$ZipFolder = "C:\temp\LogsArchive"    # Locatie voor zip-bestanden
)

# Configuratie
$MacAddressFile = "C:\temp\MacAddresses.txt"
$ScriptName = $MyInvocation.MyCommand.Name

# Controleer of het ZipFolder bestaat, maak het anders aan
if (-not (Test-Path $ZipFolder)) {
    New-Item -ItemType Directory -Path $ZipFolder | Out-Null
}

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

# Functie om actieve instanties van dit script te tellen
function Get-ScriptInstances {
    Get-Process | Where-Object { $_.Path -eq $PSCommandPath } | Measure-Object | Select-Object -ExpandProperty Count
}

# Functie om logbestanden in te pakken
function Manage-LogFile {
    # Controleer grootte van het logbestand
    if (Test-Path $LogFile) {
        $LogFileSizeKB = (Get-Item $LogFile).Length / 1KB
        if ($LogFileSizeKB -ge $LogFileSizeThresholdKB) {
            Write-Log "Log file exceeds $LogFileSizeThresholdKB KB. Archiving log file."

            # Maak een zip-bestand
            $Timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $ZipFile = Join-Path $ZipFolder "Log_$Timestamp.zip"
            Compress-Archive -Path $LogFile -DestinationPath $ZipFile -Force

            # Logbestand leegmaken
            Clear-Content $LogFile
            Write-Log "Log file archived to $ZipFile and cleared."

            # Beheer zip-bestanden als er meer zijn dan toegestaan
            $ZipFiles = Get-ChildItem -Path $ZipFolder -Filter "*.zip" | Sort-Object LastWriteTime -Descending
            if ($ZipFiles.Count -gt $MaxZipFiles) {
                $FilesToDelete = $ZipFiles | Select-Object -Skip $MaxZipFiles
                foreach ($File in $FilesToDelete) {
                    Remove-Item $File.FullName -Force
                    Write-Log "Deleted old archive: $($File.FullName)"
                }
            }
        }
    }
}

# Controleer het aantal actieve instanties
$CurrentInstances = Get-ScriptInstances
if ($CurrentInstances -gt $MaxInstances) {
    Write-Log "Maximum number of script instances ($MaxInstances) exceeded. Exiting."
    exit
}

# Controleer en beheer het logbestand
Manage-LogFile

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
    Write-Log "30% or more of MAC addresses have changed or disappeared!"
    # Voeg hier een extra actie toe, zoals een e-mailnotificatie of alarm.
}

# Logging start
Write-Log "Starting MAC address monitoring script."
Write-Log "Threshold percentage set to $ThresholdPercentage%."
Write-Log "Log file location: $LogFile."
Write-Log "Maximum script instances allowed: $MaxInstances."
Write-Log "Current running instances: $CurrentInstances."
Write-Log "Log file size threshold: $LogFileSizeThresholdKB KB."
Write-Log "Maximum zip files allowed: $MaxZipFiles."

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
