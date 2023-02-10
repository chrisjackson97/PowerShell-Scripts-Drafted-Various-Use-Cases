##This Powershell script set Microsoft Exchange Server 2016/2019 Antivirus Exclusions for Windows Defender
#Original Author of Script: Jeff Guillet 
#Revised Script Author: Chris Jackson
#Reference Original Script written by Jeff: https://blog.expta.com/2021/06/script-to-set-exchange-server-antivirus.html

#Reference to All Microsoft Exchange Server Exclusions:
# https://docs.microsoft.com/en-us/Exchange/antispam-and-antimalware/windows-antivirus-software?view=exchserver-2019


#Ensure to run this entire script within the Exchange Management Server(EMS) and not just the regular Powershell terminal
$eval = Get-Module -ListAvailable Defender
if ($eval -eq $null) {
	Write-Host "Windows Defender is not installed on" (Get-WmiObject -class Win32_OperatingSystem).Caption
	Exit
}

$ExchangeInstallPath = $Env:ExchangeInstallPath -replace ".$" #$Env.ExchangeInstallPath within EMS will provide install path of server, default path is C:\Program Files\Microsoft\Exchange Server\V15\

$excludedPaths = @( "$Env:SystemDrive\ExchangeSetupLogs", `
	"$ExchangeInstallPath", `
	"$Env:WinDir\SoftwareDistribution", `
	"$Env:SystemRoot\Cluster", `
	"$Env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files", `
	"$Env:SystemRoot\System32\Inetsrv" ), `
	"$Env:SystemDrive\inetpub\temp\IIS Temporary Compressed Files"

$excludedExtensions = @( "config", "chk", "edb", "jfm", "jrs", "log", "que", "dsc", "txt", "cfg", "grxml", "lzx" )

$excludedProcesses = @( "$ExchangeInstallPath\Bin\Search\Ceres\Runtime\1.0\noderunner.exe", `
	"$ExchangeInstallPath\Bin\EdgeTransport.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.AntispamUpdateSvc.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.Diagnostics.Service.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.Directory.TopologyService.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.AntispamUpdateSvc.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.EdgeCredentialSvc.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.EdgeSyncSvc.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.Notifications.Broker.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.ProtectedServiceHost.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.RPCClientAccess.Service.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.Search.Service.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.Servicehost.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.Store.Service.exe", `
	"$ExchangeInstallPath\Bin\Microsoft.Exchange.Store.Worker.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeCompliance.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeDagMgmt.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeDelivery.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeFrontendTransport.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeHMHost.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeHMWorker.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeMailboxAssistants.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeMailboxReplication.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeRepl.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeSubmission.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeTransport.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeTransportLogSearch.exe", `
	"$ExchangeInstallPath\Bin\MSExchangeThrottling.exe", `
	"$ExchangeInstallPath\Bin\OleConverter.exe", `
	"$ExchangeInstallPath\Bin\UmService.exe", `
	"$ExchangeInstallPath\Bin\UmWorkerProcess.exe", `
	"$ExchangeInstallPath\Bin\wsbexchange.exe", `
	"$ExchangeInstallPath\FIP-FS\Bin\fms.exe", `
	"$ExchangeInstallPath\Bin\Search\Ceres\HostController\hostcontrollerservice.exe", `
	"$ExchangeInstallPath\TransportRoles\agents\Hygiene\Microsoft.Exchange.ContentFilter.Wrapper.exe", `
	"$ExchangeInstallPath\FrontEnd\PopImap\Microsoft.Exchange.Imap4.exe", `
	"$ExchangeInstallPath\ClientAccess\PopImap\Microsoft.Exchange.Imap4service.exe", `
	"$ExchangeInstallPath\FrontEnd\PopImap\Microsoft.Exchange.Pop3.exe", `
	"$ExchangeInstallPath\ClientAccess\PopImap\Microsoft.Exchange.Pop3service.exe", `
	"$ExchangeInstallPath\FrontEnd\CallRouter\Microsoft.Exchange.UM.CallRouter.exe", `
	"$ExchangeInstallPath\Bin\Search\Ceres\ParserServer\ParserServer.exe", `
	"$ExchangeInstallPath\FIP-FS\Bin\ScanEngineTest.exe", `
	"$ExchangeInstallPath\FIP-FS\Bin\ScanningProcess.exe", `
	"$ExchangeInstallPath\FIP-FS\Bin\UpdateService.exe", `
	"$Env:SystemRoot\System32\Dsamain.exe", `
	"$Env:SystemRoot\System32\inetsrv\inetinfo.exe", `
	"$Env:Systemroot\System32\WindowsPowerShell\v1.0\Powershell.exe", `
	"$Env:SystemRoot\System32\inetsrv\W3wp.exe" )

$excludedPaths | ForEach {if (!(Test-Path -Path $_ )) {New-Item -ItemType Directory -Path $_ }; Add-MpPreference -ExclusionPath $_ }
$excludedExtensions | ForEach {Add-MpPreference -ExclusionExtension $_ }
$excludedProcesses | ForEach {Add-MpPreference -ExclusionProcess $_ }

#Note: To Remove any Exclusions added to WhiteList: Remove-MpPreference -ExclusionPath "<Enter Path File Here>"
    #Best to save as a variable and include @() within calling variable to begin removing exlusions off of list.
#Note: To Obtain All ExclusionPaths entered on Exlusion Paths List: Get-MpPreference