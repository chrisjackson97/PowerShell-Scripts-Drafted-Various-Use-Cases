<#
Date: 10-18-2023
Author: Christopher M. Jackson
Occupation: Sr. Cloud Solution Architect- Azure Infrastructure
Company: Microsoft

Background: The purpose of this script is to generate a VMSS within Azure via PowerShell where VMSS Configuration will be set through set variables
defining VMSS parameters for VMSS Network Interface, Login Credentials, Storage Profile and OS Gallery, and OS Profile.
Within the script, certain assumptions will be made. These include that you are utilizing an already existing Virtual Network and Subnet
to target for the VMSS. 
    - REMBEMBER: Please note that the VMSS has to reside within the same region as the Vnet, or else, your deployment will default and fail.
     Note: VMSS doesn't allow osDisk.name in Powershell Cmdlets, it is exclusively set for VM's and other components. Do not add the -Name property
     within the Set-AzVmssStorageProfile.
     
     Resource Links Used: 1.) New-AzVmssConfig: https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvmssconfig?view=azps-10.4.1
     2.) New-AzVmss: https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvmss?view=azps-10.4.1
     3.) Set-AzVmssStorageProfile: https://learn.microsoft.com/en-us/powershell/module/az.compute/set-azvmssstorageprofile?view=azps-10.4.1
     4.) New-AzVmssIpConfig: https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvmssipconfig?view=azps-10.4.1
     #>

Connect-AzAccount
$subscription = Set-AzContext -Subscription '<Please enter Subscription Name Here>' #<Enter subscription name>
$resourceGroup = Get-AzResourceGroup #Creating variable that will be array of all resource groups within subscription
$resourceGroupSelected = $resourceGroup[1] #Selecting the resource group from an array of avaialable RG's that will be used for VMSS creation
     
#------------------------------------Setting Configuration Variables for VMSS Scale Set--------------------------------------------------#
     
$VmssName = "VMSS-Test" #Name of VMSS that will be created for testing 
$VmssLocation = "central us" #location of Azure datacenter for created VMSS
$VMSkuName = "Standard_DS1_v2" #VM instance size and SKU for VMSS. Can use Get-AzComputeResourceSku to find available VM sizes for stated subscription and region
$SkuCapacity = 10 #Number of VM's that will be created within the VMSS
$UPM = 'Manual' #Specifies the mode of an upgrade to virtual machines in the VMSS. Options are manual or automatic
     
# Selecting the existing Network Configuration for IPConfiguration of VMSS
$vnet = Get-AzVirtualNetwork #Creating variable that will be array of all virtual networks within subscription
$selectedvnet = $vnet[6] #Selecting the vnet from within array of given vnets that will be used for VMSS creation
$selectedsubnetID = $vnet[6].Subnets[2].Id #Selecting the target subnet ID by array index from within selected Vnet 
$IpConfig = New-AzVmssIpConfig -Name 'Test-VMSSIPConfig' -SubnetId $selectedsubnetID #VMSS IP Configuration
     
#Credentials for Authenticating Login into the VMSS
$AdminUN = '<Please Enter Desired Admin Username>' #Admin Login to the VMSS OS System
$AdminPW = '<Please enter Desired Admin Password> ' #Admin Password to the VMSS OS System
     
#OS Selection for creation of VM image from gallery of images within Storage Profile 
$imageOffer = 'WindowsServer' #Image Offer for VMSS. Can use Get-AzVMImageOffer to find available images for stated subscription and region
$imageSKU = "2019-DataCenter" #Image SKU for VMSS. Can use Get-AzVMImageSku to find available images for stated subscription and region
$publisher = 'MicrosoftWindowsServer' #Publisher for VMSS. Can use Get-AzVMImagePublisher to for further details
$ImageVersion = 'latest' 
     
#---------------------------------Creating Deployment of VMSS Based on Configuration Variables------------------------------------------#
#Creating VMSS Configuration
$VmssConfig = New-AzVmssConfig -Location $VmssLocation -SkuCapacity $SkuCapacity -SkuName $VMSkuName -UpgradePolicyMode $UPM `
| Add-AzVmssNetworkInterfaceConfiguration -Name "VMSS-TestNet" -Primary $True -IpConfiguration $IpConfig `
| Set-AzVmssOSProfile -ComputerNamePrefix "testvmss" -AdminUsername $AdminUN -AdminPassword $AdminPW `
| Set-AzVmssStorageProfile  -OSDiskCreateOption "FromImage" -OSDiskCaching "None" `
    -ImageReferenceOffer $imageOffer -ImageReferenceSku $imageSKU -ImageReferenceVersion $ImageVersion `
    -ImageReferencePublisher $publisher
     
$product = New-AzVmss -ResourceGroupName $resourceGroupSelected.ResourceGroupName -VmScaleSetName $VmssName -VirtualMachineScaleSet $VmssConfig
$vmssInstances = Get-AzVmss #Checking to see which VMSS's are currently created within target subscription
     
     
     
     