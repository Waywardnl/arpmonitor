param (
    [int]$ThresholdPercentage = 30,               # Wijzigingspercentage
    [string]$LogFile = "C:\temp\MacAddressLog.txt", # Locatie van het logbestand
    [int]$MaxInstances = 1,                       # Maximum aantal scriptinstanties
    [int]$LogFileSizeThresholdKB = 1024,          # Maximale grootte van het logbestand in KB
    [int]$MaxZipFiles = 5,                        # Maximum aantal zip-bestanden
    [string]$ZipFolder = "C:\temp\LogsArchive",   # Locatie voor zip-bestanden
    [string]$IpRange = "192.168.1.0/24",          # IP-bereik om te scannen
    [int]$ScanIntervalSeconds = 60,               # Interval tussen scans in seconden
    [int]$MaxScans = 10                           # Maximum aantal scans
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

# Functie om een lijst van IP-adressen te genereren op basis van een IP-range
function Get-IpAddresses {
    param (
        [string]$Subnet
    )
    $Address = $Subnet.Split('/')[0]
    $MaskBits = [int]($Subnet.Split('/')[1])

    # Bereken de netwerkgrootte en IP-adressen
    $BaseIp = [System.Net.IPAddress]::Parse($Address).GetAddressBytes()
    $HostsCount = [math]::Pow(2, 32 - $MaskBits) - 2

    $Ips = @()
    for ($i = 1; $i -le $HostsCount; $i++) {
        $CurrentIp = [System.Net.IPAddress]($BaseIp)
        $CurrentIp = [System.Net.IPAddress]::HostToNetworkOrder([bitconverter]::ToInt32($BaseIp, 0) + $i)
        $Ips += [System.Net.IPAddress]::Parse($CurrentIp).ToString()
    }
    return $Ips
}

# Functie om MAC-adressen binnen een specifiek IP-bereik te verkrijgen
function Get-MacAddresses {
    param (
        [string[]]$IpAddresses
    )
    $MacAddresses = @()
    foreach ($Ip in $IpAddresses) {
        $ArpEntry = arp -a | Select-String $Ip
        if ($ArpEntry -match "([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}") {
            $MacAddresses += ($matches[0] -replace "[:-]", "-")
        }
    }
    return $MacAddresses | Sort-Object -Unique
}

# Functie om logbestanden in te pakken
function Manage-LogFile {
    if (Test-Path $LogFile) {
        $LogFileSizeKB = (Get-Item $LogFile).Length / 1KB
        if ($LogFileSizeKB -ge $LogFileSizeThresholdKB) {
            Write-Log "Log file exceeds $LogFileSizeThresholdKB KB. Archiving log file."

            $Timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $ZipFile = Join-Path $ZipFolder "Log_$Timestamp.zip"
            Compress-Archive -Path $LogFile -DestinationPath $ZipFile -Force

            Clear-Content $LogFile
            Write-Log "Log file archived to $ZipFile and cleared."

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

# Functie voor het uitvoeren van een enkele scan
function PerformScan {
    Write-Log "Performing a MAC address scan."

    # Genereer de IP-adressen van het opgegeven IP-bereik
    $IpAddresses = Get-IpAddresses -Subnet $IpRange
    Write-Log "Scanning MAC addresses in IP range: $IpRange."

    # Huidige MAC-adressen ophalen
    $CurrentMacAddresses = Get-MacAddresses -IpAddresses $IpAddresses
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

    $TotalMacs = [math]::Max($PreviousMacAddresses.Count, $CurrentMacAddresses.Count)
    if ($TotalMacs -eq 0) {
        Write-Log "No MAC addresses to compare."
        return
    }

    $ChangedPercentage = (($RemovedMacs.Count + $NewMacs.Count) / $TotalMacs) * 100
    Write-Log "Changed percentage: $ChangedPercentage%"

    if ($ChangedPercentage -ge $ThresholdPercentage) {
        Write-Log "Change detected above threshold!"
    } else {
        Write-Log "Change percentage below threshold. No action taken."
    }

    $CurrentMacAddresses | Out-File $MacAddressFile
    Write-Log "Updated MAC addresses saved."
}

# Beheer van logbestand
Manage-LogFile

# Repeterende scans uitvoeren
for ($i = 1; $i -le $MaxScans; $i++) {
    Write-Log "Starting scan iteration $i of $MaxScans."
    PerformScan
    if ($i -lt $MaxScans) {
        Write-Log "Waiting for $ScanIntervalSeconds seconds before the next scan."
        Start-Sleep -Seconds $ScanIntervalSeconds
    }
}
Write-Log "Completed all scan iterations."
