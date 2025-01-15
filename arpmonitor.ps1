# Configuratie
$MacAddressFile = "C:\temp\MacAddresses.txt"
$ThresholdPercentage = 30

# Functie om huidige MAC-adressen te scannen
function Get-MacAddresses {
    arp -a | ForEach-Object {
        if ($_ -match "([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}") {
            $matches[0]
        }
    } | Sort-Object -Unique
}

# Actie bij detectie van veranderingen
function OnChangeDetected {
    Write-Host "30% of more MAC addresses have changed or disappeared!" -ForegroundColor Red
    # Voeg hier de gewenste actie toe, zoals een notificatie of logbestand.
}

# Huidige MAC-adressen ophalen
$CurrentMacAddresses = Get-MacAddresses

# Controlebestand inladen of aanmaken
if (Test-Path $MacAddressFile) {
    $PreviousMacAddresses = Get-Content $MacAddressFile
} else {
    $PreviousMacAddresses = @()
    $CurrentMacAddresses | Out-File $MacAddressFile
}

# Vergelijken van de MAC-adressen
$RemovedMacs = $PreviousMacAddresses | Where-Object { $_ -notin $CurrentMacAddresses }
$NewMacs = $CurrentMacAddresses | Where-Object { $_ -notin $PreviousMacAddresses }

# Detecteren van wijzigingen
$TotalMacs = [math]::Max($PreviousMacAddresses.Count, $CurrentMacAddresses.Count)
$ChangedPercentage = (($RemovedMacs.Count + $NewMacs.Count) / $TotalMacs) * 100

if ($ChangedPercentage -ge $ThresholdPercentage) {
    OnChangeDetected
}

# Huidige MAC-adressen opslaan
$CurrentMacAddresses | Out-File $MacAddressFile
