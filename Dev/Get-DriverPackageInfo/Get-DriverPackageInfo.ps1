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
	  $lineToWrite = "Driver Name" + ',' + "Driver Source Path" + ',' + "Driver Version" + ',' + "Driver PackageID" + ',' + "Driver Package Name" + ',' + "Driver Package Source Path"
	  $fileName = "C:\GitHub\SCCM-Public-Scripts2\DriverPackages\" + $PackageID + ".txt"
	  $logLine = "Getting Driver Info For Package " + $PackageID
	  write-log $logLine
	  
	  #Check if driver package is new
	  $changesMade = $false
	  if((Test-Path $filename) -eq $false) {
		$changesMade = $true
		$logLine = "Package: " + $PackageID + " is a new package."
		$ChangeMSG = "(NEW PACKAGE) " + $PackageID + " - " + $PackageName + ", "
		write-log $logLine
	}
		
	  $oldFile = Get-Content $fileName
	  $lineToWrite | Out-File $fileName -Confirm:$false
	  ##Writing Driver Info For Package
		if($PackageIDToContentID.ContainsKey($PackageID)) {
			$CIDs = $PackageIDToContentID.Get_Item($PackageID)
			foreach($CID in $CIDs) {
				if($ContentIDToCIID.ContainsKey($CID)) {
					$CIIDs = $ContentIDToCIID.Get_Item($CID)
					foreach($CIID in $CIIDs) {
						foreach($i in $drivers) {
							if($i.CI_ID -eq $CIID) {
								$Name = $i.LocalizedDisplayName
								$Source = $i.ContentSourcePath
								$Ver = $i.DriverVersion
								$lineToWrite = $Name + ',' + $Source + ',' + $Ver + ',' + $PackageID + ',' + $PackageName + ',' + $PkgSourcePath
								$lineToWrite | Out-File $filename -append -confirm:$false
							}
						}
					}
				}
			}
		}

		if(!$changesMade) {
		  #CompareFiles
		  $newFile = Get-Content $fileName
		  $diff = diff $oldFile $newFile
		  if($diff.count -gt 0) {
			$changesMade = $true
			$logLine = "Changes have been made to " + $PackageID + ".txt"
			$ChangeMSG = "(changed) " + $PackageID + " - " + $PackageName + ", "
			write-log $logLine
		}
	}
  $retval = @()
  $retval += $changesMade
  $retval += $ChangeMSG
  Return $retval
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
$changesMade = $false #Variable to track if changes were made and if so a commit is needed
##Create Maps of Data
$PackageIDToContentID = @{($PTC[0].PackageID) = @($PTC[0].ContentID)}
foreach ($P in $PTC) {
	if($PackageIDToContentID.ContainsKey($P.PackageID)) {
		$PackageIDToContentID.Set_Item($P.PackageID,$PackageIDToContentID.Get_Item($P.PackageID)+$P.ContentID)
	} else {
		$PackageIDToContentID.Add($P.PackageID,@($P.ContentID))
	}
}
$ContentIDToCIID = @{($CITC[0].ContentID) = ($CITC[0].CI_ID)}
foreach($C in $CITC) {
	if($ContentIDToCIID.ContainsKey($C.ContentID)) {
		$ContentIDToCIID.Set_Item($C.ContentID,$ContentIDToCIID.Get_Item($C.ContentID)+$C.CI_ID)
	} else {
		$ContentIDToCIID.Add(($C.ContentID),@($C.CI_ID))
	}
}

#Create Change Message
$ChangeMSG = "The Following Changes Have Been Made: "

$driverPackageIDs = @()

##Output Data For Each Driver Package
foreach ($i in $driverPacks) 
    {
		$results = WriteDriverPackageToFile($i)
		if($results[0] -eq $true) {
			$changesMade = $true
			$changeMSG = $changeMSG + $results[1]
		}
		$driverPackageIDs += $i.PackageID
	}	

#Check For Deleted Packages as Files
$driverPackagePath = "C:\GitHub\SCCM-Public-Scripts2\DriverPackages\"
$driverPackageFiles = ls $driverPackagePath
$filesToRMFromGit = @()
foreach ($file in $driverPackageFiles) {
	if(!($driverPackageIDs -contains $file.BaseName)) {
		$PkgCont = Import-Csv $file.FullName
		$PackageName = ($PkgCont[0]."Driver Package Name")
		$ChangeMSG += "(REMOVED PACKAGE) " + $file.BaseName + " - " + $PackageName + ','
		$logLine = "Driver Package: " + $file.BaseName + " no longer exists, deleting file."
		write-log $logLine
		$filesToRMFromGit += $file.FullName
		$changesMade = $true
	}
}
	
#Commit to Git
if($changesMade) {
	write-log $ChangeMSG
	$logLine = "Committing Changes to Git"
	write-log $logLine
	
	git config --global user.name 'ASC-SCCM-Robot'
	git config --global user.email win-team@chem.osu.edu

	#$GitPasswd = get-content C:\Scripts\Get-DriverPackageInfo\GitPassword.txt

	$GitPath = "C:\GitHub\SCCM-Public-Scripts2"
	cd $GitPath
	git init
	$GitDriverPath = $GitPath + "\DriverPackages\*"
	git add $GitDriverPath
	foreach ($fileName in $filesToRMFromGit) {
		git rm $fileName
	}
	git commit -m $ChangeMSG
	#git remote add origin https://github.com/ASCTech/ASC-SCCM-Private.git
	git push -u SCCMRobot master
	} else {
		write-log "No Changes Have Been Made"
	}

write-log "Complete"
	
