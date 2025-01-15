param (
    [int]$ThresholdPercentage = 30,               # Wijzigingspercentage
    [string]$LogFile = "C:\temp\MacAddressLog.txt", # Locatie van het logbestand
    [int]$MaxInstances = 1,                       # Maximum aantal scriptinstanties
    [int]$LogFileSizeThresholdKB = 1024,          # Maximale grootte van het logbestand in KB
    [int]$MaxZipFiles = 5,                        # Maximum aantal zip-bestanden
    [string]$ZipFolder = "C:\temp\LogsArchive",   # Locatie voor zip-bestanden
    [string]$IpRange = "192.168.1.0/24",          # IP-bereik om te scannen
    [int]$ScanIntervalSeconds = 60,               # Interval tussen scans in seconden
    [int]$MaxScans = 10,                          # Maximum aantal scans
    [string]$CsvFile = "C:\temp\MacAddressStats.csv" # Locatie van CSV-bestand voor monitoring
)

# Configuratie
$MacAddressFile = "C:\temp\MacAddresses.txt"
$ScriptName = $MyInvocation.MyCommand.Name

# Controleer of het ZipFolder bestaat, maak het anders aan
if (-not (Test-Path $ZipFolder)) {
    New-Item -ItemType Directory -Path $ZipFolder | Out-Null
}

# Controleer of het CSV-bestand bestaat, anders maak je een nieuwe
if (-not (Test-Path $CsvFile)) {
    @"
Timestamp,TotalMACs,EqualMACs,RemovedMACs,NewMACs
"@ | Out-File -FilePath $CsvFile -Encoding UTF8
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

# Functie om een enkele scan uit te voeren
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
    $EqualMacs = $PreviousMacAddresses | Where-Object { $_ -in $CurrentMacAddresses }

    Write-Log "Removed MACs: $($RemovedMacs -join ', ')"
    Write-Log "New MACs: $($NewMacs -join ', ')"

    $TotalMacs = [math]::Max($PreviousMacAddresses.Count, $CurrentMacAddresses.Count)
    $ChangedPercentage = (($RemovedMacs.Count + $NewMacs.Count) / $TotalMacs) * 100
    Write-Log "Changed percentage: $ChangedPercentage%"

    # Opslaan in het CSV-bestand
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $CsvLine = "$Timestamp,$TotalMacs,$($EqualMacs.Count),$($RemovedMacs.Count),$($NewMacs.Count)"
    Add-Content -Path $CsvFile -Value $CsvLine
    Write-Log "Statistics saved to CSV: $CsvFile"

    if ($ChangedPercentage -ge $ThresholdPercentage) {
        Write-Log "Change detected above threshold!"
    } else {
        Write-Log "Change percentage below threshold. No action taken."
    }

    # Update het referentiebestand
    $CurrentMacAddresses | Out-File $MacAddressFile
    Write-Log "Updated MAC addresses saved."
}

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
