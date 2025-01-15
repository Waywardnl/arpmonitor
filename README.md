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
