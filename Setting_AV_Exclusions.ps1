#Start by initially seeing which Exclusions are already listed within your overall AV path
#For reference, posting the link below for more information to help better understand process of Powershell cmdlets for Defender AV

# https://learn.microsoft.com/en-us/powershell/module/defender/add-mppreference?view=windowsserver2022-ps

# https://learn.microsoft.com/en-us/powershell/module/defender/set-mppreference?source=recommendations&view=windowsserver2022-ps

#Get-MpPreference will show you all of the current preferences that are applied when a Defender scan takes place

# Precursors
Set-ExecutionPolicy RemoteSigned #---> Make sure To Input

Get-MpPreference 

$currentExclusions += (Get-MpPreference).MpExclusionPath #You will want to make sure that this is not empty array if using line 22, or it will error out as your adding a blank array to a blank array 

$exclusionPaths = @()
$exclusionPaths += "C:\Program Files\Antivirus\Exclude1"
$exclusionPaths += "C:\Program Files\Antivirus\Exclude2"
$exclusionPaths += "C:\Program Files\Antivirus\Exclude3"
$exclusionPaths += "C:\Program Files\Antivirus\Exclude4"
# $exclusionPaths += $currentExclusions   #-----> Uncomment this out if you have previous exclusions on path that need to be added, if empty array, it is going to error out and not add anything, because you would be referencing empty array
#NOTE: to delete out exclusions within this example, use---->  Remove-MpPreference -ExclusionPath "Input File Path Name Here from Exclusion List"
# Set the exlusions using Set-MpPreference along with created variable holding array of exclusion
# Note: Could also use the Add-MpPreference to include the newly created array of exclusions as well

#$(Get-MpPreference).MpExclusionPath

Set-MpPreference -ExclusionPath $exclusionPaths

#Going to set Default Action for instance whenever low threat virus is detected.
Set-MpPreference -LowThreatDefaultAction 10

# Addititional Good to Know Content

#Get-MpThreatCatalog ----> The list of all known Defender viruses, malware, attacks is quite expansive and can cause throttling issues when trying to load, just FYI
# $ThreatId = (Get-MpThreatCatalog).ThreatID ----> Stored Variable holding all current threat ID's, not necessary.
# Example--> $ThreatID = (Get-MpThreatCatalog -ThreatID 2147492856)---> Focused approach to looking up certain records/ID values of threats

Get-MpPreference

Read-Host -Prompt "Press Enter to exit"