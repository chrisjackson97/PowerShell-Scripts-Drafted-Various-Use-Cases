<#
Date: 02-14-2023
Author: Christopher M. Jackson
Occupation: Sr. Cloud Solution Architect- Azure Core 
Company: Microsoft
#>

<# The Intent of this Script is to utilize PowerShell 5.1 or 7.0 scripting to create a user, assign the user to a new security group, and then assign the security
 group relevant RBAC. For PowerShell, please note that while the commands for creation are straight-forward,there is alot of nuance in the proper modules being set up.
  Before Completing any of the code below, please ensure to go thorugh the Prerequisites section below! #>

#---------------------------------------------#Prerequisites-------------------------------------------------------------------------------------------------

<#Note, to create users, you need to use AzureADPreview module and not just AzureAD.
Ref: https://stackoverflow.com/questions/62929165/new-object-cannot-find-type-microsoft-open-azuread-model-domainfederationsett
If you don't have AzureADPreview, when attempting to create a Password Profile as all the 
Microsoft documentation guides you to do: https://learn.microsoft.com/en-us/powershell/module/azuread/new-azureaduser?view=azureadps-2.0

You will encounter the following error: New-Object: Cannot find type [Microsoft.Open.AzureAD.Model.PasswordProfile]: verify that the assembly containing this type is loaded.#>


#Use the following lines of the script(Lines 26-30) if AzureADPreview is not an active module within your Azure Powershell modules
#Also install and import the the AzureAD module https://stackoverflow.com/questions/69519144/cannot-find-type-microsoft-open-azuread-model-resourceaccess-when-using-graph-mi
    # - This can commonly be the case as well if you have downloaded and installed a new version of PowerShell as this module is not installed by default

 Install-Module -Name AzureADPreview -AllowClobber 
 Install-Module AzureAD -Scope CurrentUser -Force -AllowClobber
 Import-Module AzureAD -Force -AllowClobber
 Install-Module Microsoft.Graph
 Import-Module Microsoft.Graph 

<# NOTE!! Will run into issues using Connect-AzureAD in Pwsh 7.0 since created for cross-platform
   via .NET Core and not purely just for Windows. Issues will occur with: 
   'Could not load type 'System.Security.Cryptography.SHA256Cng'

        - .Net Framework for Cryptography works fine on Pwsh 5.1 however, as this was made purely for 
        Windows platform. 
         - The workaround as of Feb. 2023 until Azure AD PG or Microsoft Graph PowerShell
            group addresses issues noted since 2020 is to first install both the  
            Installing-Module AzureAD from lines 27 and the Import-Module AzureAD -Force -AllowClobber
            from line 28 on your PowerShell 5.1 terminal. 
        - After completing this step, if wanting to utilize on Pwsh 7.0, you will then need to run the 
          following line below( Line 46) to trigger WinPSCompatSession remoting session to use all functionality and 
          compatibility of Pwsh 5.1 within  your Pwsh 7.0 terminal.#>

          # Import-Module AzureAD -UseWindowsPowerShell #Uncomment if using Powershell 7.0 instead of PowerShell 5.1

          <#Ref: https://github.com/PowerShell/PowerShell/issues/10473
             #  https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_windows_powershell_compatibility?view=powershell-7.3&viewFallbackFrom=powershell-7
              # https://www.sharepointdiary.com/2020/01/import-module-specified-module-not-loaded-because-no-valid-module-file-found-in-any-module-directory.html
         
          - You will know it worked if you get something similar to the following:

          WARNING: Module AzureAD is loaded in Windows PowerShell using WinPSCompatSession remoting session;
           please note that all input and output of commands from this module will be deserialized objects. 
           If you want to load this module into PowerShell please use 'Import-Module -SkipEditionCheck' syntax.


#>
#_--------------------------------------------Adding a Single New User-------------------------------------------------------------------------------------------------

$UserName = "<Enter New User's Name>" #Setting local variables to be placed within New-AzureADUser cmdlet on line 85
$UserPrincipalName = "<Enter New User's User Principal Name>"
$PrimaryDomain = "<Enter Primary Domain, please include the '.com' at the end of domain>"

$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile

$Password = "< Enter a new Password>" <#Note, if when running line 85, you get an error noting: 
                             New-AzureADUser: Cannot bind parameter 'PasswordProfile'. Cannot convert the "-class PasswordProfile,value of type
                             "System.String" to type "Microsoft.Open.AzureAD.Model.PasswordProfile" 
                           
                             Follow lines  68-79 first. If this is not applicable from issue mentioned above, jump to Line 84
                             Ref: https://stackoverflow.com/questions/19188761/can-not-convert-string-to-secure-string-for-use-in-new-aduser   #>

$PasswordSecured = ConvertTo-SecureString $Password -AsPlainText -Force
$Password = $PasswordSecured
$Password.GetType() <#Verify that the System Object is Type Secure String now. The Name column of the output of this command should display
                     Name as SecuredString#>
$PasswordProfile.Password = $Password <#Must add Password in this manner to ensure it is a secure string
                                      or user profile will fail to bind parameter $PasswordProfile 
                                       to New-AzureADUser#>


Connect-AzureAD
New-AzureADUser -DisplayName $UserName -PasswordProfile $PasswordProfile -UserPrincipalName $UserPrincipalName+"@"+$PrimaryDomain -AccountEnabled $true -MailNickName "Newuser"

<#Ex. Provided below of New User.)

 New-AzureADUser -DisplayName "New User" -PasswordProfile $PasswordProfile -UserPrincipalName "NewUser@contoso.com" -AccountEnabled $true -MailNickName "Newuser"
#>

#------------------------------------------Creating a New Azure AD Security Group----------------------------------------------------------------------------------------------------

# Ref: https://learn.microsoft.com/en-us/powershell/module/azuread/new-azureadgroup?view=azureadps-2.0

$UserGroupName = "<Please Enter New User Group Name>"

New-AzureADGroup -DisplayName $UserGroupName -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet"

<#Ex.)

New-AzureADGroup -DisplayName "DevTest Group" -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet"
#> 

#_-------------------------------------Adding Users to Created Security Group --------------------------------------------------------------------------------------------------------

$UsersforSG= @() # Creating a blank array to add all users into specified group for. Primary Point of Focus is the Object Id of each User in the output

$UsersforSG += (Get-AzureADUser -SearchString "<Enter DisplayName of User You are Searching For") 
$UsersforSG += (Get-AzureADUser -SearchString "<Enter DisplayName of User You are Searching For")
$UsersforSG += (Get-AzureADUser -SearchString "<Enter DisplayName of User You are Searching For")<# Continue this for however many particular users 
                                                                                                    you are searching for#>

#Ex. of Finding a User ) $UsersforSG += (Get-AzureADUser -SearchString "New User") 

$UserObjectID = $UsersforSG.ObjectId #Including All User's Object ID's in a new variable for reference

$SGGroupName = @() #Including single SecurityGroup within blank array for User Groups
$SGGroupName += (Get-AzureADGroup -SearchString "<Enter DisplayName of User Group that You are Searching For")

#Ex. of Finding a User Group) $SGGroupName += (Get-AzureADGroup -SearchString "DevTest Group")

$SGGroupObjectID = $SGGroupName.ObjectId #Including User Group  Object ID in a new variable for reference

foreach($user in $UserObjectID){
    Add-AzureADGroupMember -ObjectId $SGGroupObjectID -RefObjectId $user
}

Get-AzureADGroupMember -ObjectId $SGGroupObjectID #Verify that your selected users are within proper UserGroup now. Note: Users can only be
                                                  # part of one group

<#Ref: https://thesysadminchannel.com/how-to-add-users-to-an-azure-ad-group-using-powershell/
      https://learn.microsoft.com/en-us/powershell/module/azuread/get-azureadgroupmember?view=azureadps-2.0 #>

#--------------------------------------Assigning Role to the Security Group--------------------------------------------------------------------

# Ref: Placing Microsoft Reference Document for all RBAC Roles and ID: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#managed-services-registration-assignment-delete-role
$RoleDefName = "<Enter RBAC Role to Which You want to Assign to the Security Group>"
$SubID = "<Enter RBAC Role to Which You want to Assign to the Security Group>"

<#Will continue to build onto Security Group created in previous section#> 
New-AzRoleAssignment -ObjectId $SGGroupObjectID `
-RoleDefinitionName $RoleDefName `
-Scope /subscriptions/$SubID

Get-AzRoleAssignment -ObjectId $SGGroupObjectID #Verify all Roles assigned to the security group
