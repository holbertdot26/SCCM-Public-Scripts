##LOG FILE FUNCTION
function write-log([string]$info){            
    if($loginitialized -eq $false){            
        $FileHeader | Out-File $logfile -Append -Confirm:$false            
        $script:loginitialized = $True            
    }            
    $info | Out-File $logfile -Append -Confirm:$false         
}            
   
##############################################################################

Function WriteDriverPackageToFile($ThisDriverPackage)
{
trap [Exception] { 
      write-log
      write-log $("TRAPPED: " + $_.Exception.GetType().FullName); 
      write-log $("TRAPPED: " + $_.Exception.Message); 
      continue; 
	  }
	  ##Writing Driver Package Header
	  $PackageID = $ThisDriverPackage.PackageID
	  $PackageName = $ThisDriverPackage.Name
	  $PkgSourcePath = $ThisDriverPackage.PkgSourcePath
	  $lineToWrite = $PackageID + ',' + $PackageName + ',' + $PkgSourcePath
	  $fileName = "C:\logs\Get-DriverPackageInfo\" + $PackageID + ".txt"
	  $lineToWrite | Out-File $fileName -Confirm:$false
	  $logLine = "Getting Driver Info For Package " + $PackageID
	  write-log $logLine
	  ##Writing Driver Info For Package
#	  foreach($i in $PTC) {
#		if($i.PackageID -eq $PackageID) {
#			$CUID = $i.ContentUniqueID.toUpper()
#			foreach($j in $CITC) {
#				if($j.CI_UniqueID.toUpper() -eq $CUID) {
#					$CIID = $j.CI_ID.toUpper()
#					foreach($k in $drivers) {
#						if($k.CI_ID.toUpper() -eq $CIID) {
#							$Name = $k.LocalizedDisplayName
#							$Source = $k.ContentSourcePath
#							$Ver = $k.DriverVersion
#							$lineToWrite = $Name + ',' + $Source + ',' + $Ver
##						}
#				}
#				}
#			}
#		}
#	}
	
	  $logLine = "Wrote Information For Package " + $PackageID
	  write-log $logLine
  
}	  



##########################################################################################
<#---------Logfile Info----------#>            
$script:logfile = "C:\logs\Get-DriverPackageInfo\Get-DriverPackageInfo-$(get-date -format MMddyyHHmmss).log"            
$script:Seperator = @"

$("-" * 25)

"@            
$script:loginitialized = $false            
$script:FileHeader = @"
$seperator
***Application Information***
Filename:  Get-DriverPackageInfo.ps1
Created by:  Holbert.26
"@       

# Aliases for Get-LogicalDisk
	set-alias -name Get-Storage -value Get-LogicalDisk -Scope Global -Option AllScope -Description "Alias for get-logicaldisk."
	set-alias -name st -value Get-LogicalDisk -Scope Global -Option AllScope -Description "Alias for get-logicaldisk."

############################################################################################
	
##Main	
trap [Exception] { 
      write-log
      write-log $("TRAPPED: " + $_.Exception.GetType().FullName); 
      write-log $("TRAPPED: " + $_.Exception.Message); 
      continue; 
}

##Get SCCM Driver Packages, Drivers, And Linking Files
write-log "Getting SCCM Driver Packages"
$driverPacks = Get-WmiObject SMS_DriverPackage -namespace root\sms\site_chm
write-log "Getting SCCM Drivers"
$drivers = Get-WmiObject SMS_Driver -namespace root\sms\site_chm
write-log "Getting PackageToContent"
$PTC = Get-WmiObject SMS_PackageToContent -namespace root\sms\site_chm
write-log "Getting CIToContent"
$CITC = Get-WmiObject SMS_CIToContent -namespace root\sms\site_chm
##Create Table Of Drivers With Information
$driverTable
foreach($driver in $drivers) {
	$CIID = $driver.CI_ID
	$logLine = "Checking Driver " + $driver.LocalizedDisplayName
	write-log $logLine
	foreach ($CI in $CITC) {
		if($CI.CI_ID -eq $CIID) {
			$CUID = $CI.CI_UniqueID.ToUpper()
			$logLine = "Checking CI_UniqueID " + $CUID
			write-log $logLine
			foreach ($P in $PTC) {
			write-log ($P.ContentUniqueID.ToUpper())
				if($CUID.Contains($P.ContentUniqueID.ToUpper())) {
					write-log ($driverTable.count)
					$properties=@{'Name'=$driver.LocalizedDisplayName;
					'Source'=$driver.ContentSourcePath;
					'Version'=$driver.DriverVersion;
					'Package'=$P.PackageID}
					$driverObject = New-Object -TypeName PSObject -Prop $properties
					$logLine = "Found PackageID " + $driverObject.Package
					write-log $logLine
					write-log $driverObject
					$driverTable = $driverTable + $driverObject
				}
			}
		}
	}
}

##Output Data For Each Driver Package
foreach ($i in $driverPacks) 
    {
		WriteDriverPackageToFile($i)
	}	

write-log "Complete"
	
