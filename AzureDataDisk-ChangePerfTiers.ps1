<#
Date: 02-09-2023
Author: Christopher M. Jackson
Occupation: Sr. Cloud Solution Architect- Azure Core 
Company: Microsoft
References: https://learn.microsoft.com/en-us/azure/virtual-machines/windows/attach-disk-ps
            https://charbelnemnom.com/change-performance-tiers-of-azure-managed-disk/

#-----------------------------------------------------------------------------------------------------------------------------------------
#Changing Already Existing DataDisk to a Higher or Lower Performance Tier
#------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------------------------------------------------
 Please note, you may only downgrade your performance tier once evevery 12 hours for Premium SSD Managed Disk ONLY. Also, bear in mind, 
   the downgrade is determined solely off of your baseline. If your baseline Performance Tier was a P10 Disk, you may set upgrades and 
   downgrades to that up/down to that exact baseline
    -Ex.) Upgrading from P10 to P20 and then back down to a P10 is possible once every 12 hours
            - What is not possible is downgrading from a P10 to P6 or anything lower. Your baseline is very important! #>
#--------------------------------------------------------------------------------------------------------------------------------------

#Parameter variables set for context: 
Param
(
$subscriptionId='<Enter Your Subscription ID>',
$resourceGroupName='<Enter Target Resource Group>',
$diskPrefix='<Enter Disk Prefix Name (ex. TestDisk)>',
$diskNum = 0, #Initializer variable prior to being placed into loop
$diskName= $diskPrefix+[string]$diskNum, #Concatenates the string variable $diskPrefix with a int32 converted to string variable $diskNum
$diskSizeInGiB= 1024,    #Important selection point based size and performance matrix for Premium SSD Azure Disk. Choose wisely!
$performanceTier='P30', #Primary selection point to base selection of size and performance of Disk from 
$sku='Premium_LRS', #This code will only be applicable for Premium SSD, either within LRS or ZRS standpoint
$region='eastus' #Choose the Azure Region to which you would like the Azure Disk to be located in

)
#--------------------------------------------------------------------------------------------------------------------------------------------
#Login for Azure Account and Set Subscription Context

Connect-AzAccount #Connecting to Azure
Set-AzContext -Subscription $subscriptionId #Selecting Proper Subscription for Target Resources

Get-AzProviderFeature -FeatureName "LiveTierChange" -ProviderNamespace "Microsoft.Compute" #See if Live Tier Change is registered

Register-AzProviderFeature -FeatureName "LiveTierChange" -ProviderNamespace "Microsoft.Compute" #If not, proceed to register using the following
#---------------------------------------------------------------------------------------------------------------------------------------------
#Initialized Variables to Parse through within Azure Subscription

$VMs = Get-AzVM -ResourceGroupName $resourceGroupName -Status #Gives Primary Attributes of all VM's within selected Resource Group
$VMStatus = Get-AzVM -ResourceGroupName $resourceGroupName -Status | Select PowerState #Provides Power State of all VM's within selected Resource Group
$LUNcount = 0 # Logical Unit Number for Azure Disk, Setting at 0 to begin initializer variable for for loop
#--------------------------------------------------------------------------------------------------------------------------------------------
#Outer for-loop will parse through each VM within resource group and grab Azure Disk info, add 1 to the diskNum and $Luncount counters, and 
#update the diskName variable to reflect diskPrefix(which is a prefix entry string TestDisk) + diskNum as output(i.e. TestDisk1, TestDisk2, etc) 

foreach($vm in $VMs){
    $Disk = Get-AzDisk -ResourceGroupName $resourceGroupName 
    $diskNum+=1
    $LUNcount += 1
    $diskName= $diskPrefix+[string]$diskNum
    
    #Inner for-loop will parse each Disk within the VM's and determine based on conditionals below whether to update or create an Attached Data Disk
    foreach($disk in $Disk){
        if($disk.Name -cnotmatch " " -and $disk.Tier -ne $performanceTier -and $disk.Sku -eq $sku){

            $CurDiskName = $disk.Name
            $UpdateDiskConfig = New-AzDiskUpdateConfig  -Tier $performanceTier 
            Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $CurDiskName -DiskUpdate $UpdateDiskConfig
        }
        else{
           #Creating DiskConfiguration for New Disk and Assigning Disk Configuration to NewDisk variable. Once complete, going to update the VM
           $diskConfig = New-AzDiskConfig -SkuName $sku -Location $region -CreateOption Empty -DiskSizeGB $diskSizeInGiB -Tier $performanceTier
           $NewDisk = New-AzDisk -DiskName $diskName -Disk $diskConfig -ResourceGroupName $resourceGroupName
           $vm = Add-AzVMDataDisk -VM $vm -Name $diskName -Caching ReadWrite -DiskSizeinGB $diskSizeInGiB -CreateOption Attach -ManagedDiskId $NewDisk.Id -LUN $LUNcount 
           Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm
        }
        }
    }
     
#----------------------------------------------------------------------------------------------------------------------------------------------
#Checking the status of the Performance Tiers now for reference
#----------------------------------------------------------------------------------------------------------------------------------------------

$disknew = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $_
$disknew.Tier
