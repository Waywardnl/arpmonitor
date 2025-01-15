I Did this one with ChatGPT
----------------

Uitleg
Netwerk scannen: Het script gebruikt arp -a om de MAC-adressen op te halen.
Opslaan en vergelijken: MAC-adressen worden opgeslagen in een bestand en vergeleken met de nieuwe scan.
Detectiepercentage: Als 30% of meer van de MAC-adressen is veranderd of verdwenen, wordt een actie uitgevoerd.

------------
Gebruik
Logbestand locatie:
Pas de variabele $LogFile aan naar de gewenste locatie.
----------------
Wat is gewijzigd?
Parameters toegevoegd:
$ThresholdPercentage: Bepaalt het wijzigingspercentage waarbij actie wordt ondernomen. Standaardwaarde is 30%.
$LogFile: Locatie van het logbestand. Standaardwaarde is C:\temp\MacAddressLog.txt.
Logboeklocatie loggen:
Het script logt nu waar het logbestand wordt opgeslagen.
Voorbeeld gebruik
Standaard uitvoeren:

powershell
Copy code
.\DetectMacChanges.ps1
Met aangepaste parameters:

powershell
Copy code
.\DetectMacChanges.ps1 -ThresholdPercentage 40 -LogFile "D:\Logs\MacAddressLog.txt"
Logbestand controleren:

Open het logbestand ($LogFile) om de uitvoer te bekijken.
Opmerkingen
Zorg ervoor dat de opgegeven paden (zoals $LogFile en $MacAddressFile) toegankelijk zijn.
Voeg een validatie toe voor ongeldige parameters als dat nodig is.
--------------
Voorbeeldgebruik
Standaarduitvoering:

powershell
Copy code
.\DetectMacChanges.ps1
Met aangepaste parameters:

powershell
Copy code
.\DetectMacChanges.ps1 -ThresholdPercentage 40 -LogFile "D:\Logs\MacLog.txt" -MaxInstances 2
Resultaat in logbestand: Als er te veel instanties draaien:

scss
Copy code
[2025-01-15 15:00:00] Maximum number of script instances (1) exceeded. Exiting.
Belangrijk
Rechten: Zorg dat de gebruiker rechten heeft om processen te inspecteren en logbestanden te schrijven.
Logginglocatie: Pas $LogFile aan naar een geschikte locatie.

------------------

Voorbeeldgebruik
Met standaardwaarden:

powershell
Copy code
.\DetectMacChanges.ps1
Met aangepaste parameters:

powershell
Copy code
.\DetectMacChanges.ps1 -ThresholdPercentage 40 -LogFile "D:\Logs\MacLog.txt" -MaxInstances 2 -LogFileSizeThresholdKB 512 -MaxZipFiles 10
Let op
Zorg ervoor dat het opgegeven zip-pad ($ZipFolder) toegankelijk is.
De logbestanden worden alleen gecomprimeerd als de limiet wordt overschreden. Tot die tijd blijft het script normaal functioneren.
-----------------------
Parameter $IpRange:
Gebruiker kan een IP-bereik specificeren in CIDR-notatie (bijv. 192.168.1.0/24).
Functie Get-IpAddresses:
Genereert een lijst van IP-adressen binnen het opgegeven subnet.
Functie Get-MacAddresses:
Beperkt de MAC-adresdetectie tot alleen de opgegeven IP-adressen.
Voorbeeldgebruik
Standaard:

powershell
Copy code
.\DetectMacChanges.ps1
Met aangepast IP-bereik:

powershell
Copy code
.\DetectMacChanges.ps1 -IpRange "192.168.0.0/24" -ThresholdPercentage 20
Let op
Het script maakt gebruik van de arp-tool om MAC-adressen op te halen. Het is belangrijk dat de IP-adressen in het bereik eerder zijn gepingd om ARP-tabelvermeldingen te genereren.
Zorg ervoor dat de gebruiker voldoende rechten heeft voor netwerkbewerkingen.
-------------------
Nieuwe Parameters:
$ScanIntervalSeconds: Tijd tussen scans in seconden.
$MaxScans: Maximum aantal scans dat het script uitvoert.
Repeterende Scans:
Het script voert meerdere scans uit in een lus, met een wachttijd van $ScanIntervalSeconds tussen elke scan.
Logging per Iteratie:
Elke scan wordt gelogd, inclusief het huidige scan-nummer en totale scans.
Voorbeeldgebruik
Standaardinstellingen:

powershell
Copy code
.\DetectMacChanges.ps1
Met aangepaste parameters:

powershell
Copy code
.\DetectMacChanges.ps1 -IpRange "192.168.0.0/24" -ThresholdPercentage 20 -ScanIntervalSeconds 120 -MaxScans 5
Let op
Als $MaxScans is ingesteld op 1, wordt het script slechts één keer uitgevoerd.
Het interval is belangrijk om te zorgen dat het netwerk voldoende tijd heeft om wijzigingen te detecteren.
---------------------
Wat is nieuw?
CSV-Logging:

Het script schrijft per scan een regel in een CSV-bestand met de volgende kolommen:
Timestamp: Tijdstip van de scan.
TotalMACs: Totaal aantal MAC-adressen gedetecteerd.
EqualMACs: Aantal MAC-adressen dat onveranderd is gebleven.
RemovedMACs: Aantal MAC-adressen dat verwijderd is.
NewMACs: Aantal MAC-adressen dat nieuw is toegevoegd.
CSV Initialisatie:

Als het bestand nog niet bestaat, maakt het script een nieuw CSV-bestand met headers.
Logging naar CSV:

Per scan worden de statistieken toegevoegd als een nieuwe regel in het CSV-bestand.
