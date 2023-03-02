<#
Date: 03-01-2023
Author: Christopher M. Jackson
Occupation: Sr. Cloud Solution Architect- Azure Core 
Company: Microsoft
References: https://learn.microsoft.com/en-us/azure/expressroute/expressroute-howto-erdirect
            #>
#The purpose of this script is to more easily index and search from all available Express Route Direct circuits for the available and preferred of one's choice.
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
Connect-AzAccount
Set-AzContext -Subscription "<Enter Subscription Name or Subscription ID here>"
Register-AzProviderFeature -FeatureName AllowExpressRoutePorts -ProviderNamespace Microsoft.Network

#Get-AzSubscription #Locate subscription that ExpressRoutePorts Feature was added to if need be
Set-AzContext -Subscription "<Enter Subscription Name or Subscription ID here>"
Register-AzResourceProvider -ProviderNamespace "Microsoft.Network" #Reregister Microsft.Network Provider to now be able to use ExpressRoutePorts

$loc = Get-AzExpressRoutePortsLocation

$Names = $loc.Name
$LocList = @()

$LengthNames = $Names.Length #Setting last value of index within array as total length count of variable $Names. This indicates how many express
                             #Route locations there are by name

$Search = "New-York" #Search Query by the Location Preference that you have in mind. This can be a country, state, or any key words that will
                     #Help determine the Express Circuit location. Note that this general search can be very broad.

# $Search = Read-Host -Prompt "Enter Name of State" #Alternatively, uncomment this line if you and comment out Line 26 if wanting to prompt user for entry

$LocList += $Names[0..$LengthNames] -match $Search #List will expand to include every new entry found that matches your string description

$FinalList = @() #The variable FinalList will contain the final output of the list
foreach($entry in $LocList){
    $FinalList += Get-AzExpressRoutePortsLocation -LocationName $entry
}



