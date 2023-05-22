<#
Date: 05-19-2023
Author: Christopher M. Jackson
Occupation: Sr. Cloud Solution Architect- Azure Core 
Company: Microsoft

Purpose:
<#The purpose of this script is to more easily index and search for Vnets that are associated with S2S VPN Gateways,
 UDR's that hop to Virtual Applicances/Firewalls ,and search identification of Firewalls within a given Azure Subscription.

 Please note, there will be a file saved when running the method FindVnets within the Vnet Class. The file will be saved
 to the prefered directory listed within the Export-CSV cmdlet on lines 87,95, 96, 107. To overwrite and existing file, 
 keep the "-Append" and "-Force" cmdlet parameters. If creating an entirely new file, remove the "-Append" and "-Force"
parameters. It is advised to save the file under a different name to avoid overwriting the existing file if creating a
new file as well. Can take the .CSV and open within Excel utilizing the delimiter "," to view the data in a more readable manner.

CRITICAL TO REMEMBER: This script will only work if the user has the proper permissions to access the target subscription
                      on hand. Do not attempt to apply this code to multiple subscriptions at once as it will fail.
                      Apply on a subscription by subscription basis referencing Line 31 to change indices in sub.array. 
#>
#----------------------------------------------------------------------------------------------------------------------
class Vnet{
    $AllSubscriptions
    $ResourceGroupNames
    
    FindVnets($ResourceGroupNames,$AllSubscriptions){
        $this.ResourceGroupNames = $ResourceGroupNames #Setting constructor to call in variables from the Vnet Class into this method
        $this.AllSubscriptions = $AllSubscriptions #Setting constructor to call in variables from the Vnet Class into this method

#--------------------------------Choose Your Subscription out of Array of All Subscriptions Within Tenant-------------------
        $Inp = 2 #From List of Outputs, select the target subscription within tenant from array starting from index 0.
                 #Target subscription within an index array of available subscriptions within tenant. Index starts at 0.
 #---------------------------------------------------------------------------------------------------------------------       
        $AllTenantID = $AllSubscriptions.TenantId #Declaring Variable for the Tenant ID of the current Tenant's context
        $AllSubID = $AllSubscriptions.SubscriptionId #Retrieving the Subscription ID of the current Tenant's context
        $TenantID = $AllTenantID[$Inp] #Setting the Tenant ID to the target subscription within the array
        $SubID = $AllSubID[$Inp] #Setting the Subscription ID to the target subscription within the array

        # Initialize the log file
         $logFile = ".\Desktop\Vnets_Scanned_Output.txt"
        " --- Start of VNets Scanned ---" | Out-File $logFile

        Connect-AzAccount -Subscription $AllSubscriptions[$Inp] 
        Set-AzContext -SubscriptionName $AllSubscriptions[$Inp] 

        #Initializing variables to be used in the foreach loop that indexes through the Resource Groups of target subscription
        $rgvnet = ''
        $rgVPN = ''
        $rgFW = ''
        $rgRouteTable = ''
        $rgPeerings = ''
        $rgOnPremGateway = ''
        $rgGatewayType = ''
        $rgRoutes = ''
        $VnetaddedToList = 0 #Initializing counter for the amount of Vnets that are added to the list
        $FWaddedtoList = 0   #Initializing counter for the amount of Firewalls that are added to the list
        $UDRaddedtoList = 0  #Initializing counter for the amount of UDR's that are added to the list

        foreach($rg in $ResourceGroupNames){
            $rgvnet = Get-AzVirtualNetwork -ResourceGroupName $rg -WarningAction Ignore #Finds Vnets within the Resource Group
            $rgVPN = Get-AzVirtualNetworkGateway -ResourceGroupName $rg -WarningAction Ignore #Finds VPN Gateways within the Resource Group
            $rgFW = Get-AzFirewall -ResourceGroupName $rg -WarningAction Ignore #Finds Firewalls within the Resource Group
            $rgRouteTable = Get-AzRouteTable -ResourceGroupName $rg -WarningAction Ignore #Finds Route Tables within the Resource Group
            $rgPeerings = $rgvnet.VirtualNetworkPeerings #Fidns Virtual Network Peerings within the Resource Group
            $rgOnPremGateway = Get-AzLocalNetworkGateway -ResourceGroupName $rg -WarningAction Ignore  #Finds on Prem Local Gateways 
            $rgGatewayType = $rgOnPremGateway.GatewayType #Finds the Gateway Type for the Local Gateway- This script is looking for S2S specifically
                                                          #Gateway Types: ExpressRoute, Vpn, and LocalGateway. S2S uses Vpn                                            
            
            if($null -ne $rgvnet){
                $VnetaddedToList += 1
                Write-Host "Virtual Network Detected in TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg `n Total amount of Vnets to be evaluated: $VnetaddedToList"
                "Virtual Network Detected in TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg `n Total amount of Vnets to be evaluated: $VnetaddedToList"| Out-File $logFile -Append
            } 

            if($null -eq $rgRouteTable){
                Write-Host "There are no Route Tables in the following Tenant ID: $TenantID within SubscriptionID:$SubID in Resource Group: $rg"
                "There are no Route Tables in the following Tenant ID: $TenantID within SubscriptionID:$SubID in Resource Group: $rg"| Out-File $logFile -Append
            }
            else{
                $rgRoutes = Get-AzRouteConfig -RouteTable $rgRouteTable -WarningAction Ignore  # Using Route Config to find the Network Next Hop Type within 
                                                                                               # Route Tables. This is ultimately to find the UDR's that are 
                                                                                               # forwarding traffic to the firewall. 
                if($null -ne $rgRoutes.Name -and $rgRoutes.NextHopType -match "VirtualAppliance"){
                    $UDRaddedtoList += 1
                    Write-Host "Success! Located UDR(s) in the following TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg `n Total amount of UDR(s) included from all RGs: $UDRaddedtoList"
                    "Success! Located UDR(s) in the following TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg `n Total amount of UDR(s) included from all RGs: $UDRaddedtoList"| Out-File $logFile -Append
                    $rgRoutes | Export-Csv -Path .\Desktop\IndexingVnets -NoTypeInformation -Delimiter "," -Append -Force #Exporting the UDR's to a CSV file
                    
                    }
            }
            if($null -ne $rgVPN.Name  -and $rgGatewayType -contains "Vpn" -and $null -ne $rgPeerings.Name){
                $VnetaddedToList += 1 
                Write-Host "Success! Located target Virtual Network(s) in the following TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg `n Total amount of active applicable Vnets included from all RGs: $VnetaddedToList"
                "Success! Located target Virtual Network(s) in the following Tenant ID: $TenantID within SubscriptionID:$SubID in Resource Group: $rg `n Total amount of active applicable Vnets included from all RGs: $VnetaddedToList"| Out-File $logFile -Append
                $rgvnet | Export-Csv -Path .\Desktop\IndexingVnets -NoTypeInformation -Delimiter "," -Append -Force #Exporting the Vnets to a CSV file  
                $rgPeerings | Export-Csv -Path .\Desktop\IndexingVnets -NoTypeInformation -Delimiter "," -Append -Force #Exporting the Peerings to a CSV file         
            }
            else{
                Write-Host "There are no applicable Virtual Networks that meet all search criteria within the following TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg"
                "There are no applicable Virtual Networks that meet all search criteria within the following TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg `n"| Out-File $logFile -Append
            }

            if($null -ne $rgFW.Name){
                $FWaddedtoList += 1
                Write-Host "Success! Located the following Firewalls in the following TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg `n Total amount of Firewalls included from all RGs: $FWaddedtoList"
                "Success! Located the following Firewalls in the following TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg `n Total amount of Firewalls included from all RGs: $FWaddedtoList"| Out-File $logFile -Append
                $rgFW | Export-Csv -Path .\Desktop\IndexingVnets -NoTypeInformation -Delimiter "," -Append -Force #Exporting the Firewalls to a CSV file
            } 
            else{
                    Write-Host "There are no Firewalls in the following following TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg "
                    "There are no Firewalls in the following following TenantID: $TenantID within SubscriptionID: $SubID in ResourceGroup: $rg "| Out-File $logFile -Append 
                }
            }
        }
          
            }

    
#----------------------------- All Scope Variables for Vnet Class--------------------------------------------------------
#Enter the values for variable assignments below 
$Vnets = [Vnet]::new() #Creating object for Vnet Class
$Vnets.AllSubscriptions = Get-AzSubscription 
$Vnets.ResourceGroupNames = Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName
$Vnets.FindVnets($Vnets.ResourceGroupNames,$Vnets.AllSubscriptions) #Calling the FindVnets method from the Vnet Class