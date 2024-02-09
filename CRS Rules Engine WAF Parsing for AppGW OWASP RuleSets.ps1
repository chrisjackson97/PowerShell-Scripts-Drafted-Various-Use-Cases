<#
Date: 02-08-2024
Author: Christopher M. Jackson
Occupation: Sr. Cloud Solution Architect- Azure Infrastructure
Company: Microsoft

Background: The purpose of this script is to provide an automated resolution to detecting changes within selected OWASP CRS Rules Engines
as per relevant to the mangaed rules engines that Microsoft aligns to for their Web Application Firewall(WAF) Policies for App Gateway Azure
resources.This provided script will serve as an example of how to actively parse through the output given by PS cmdlet Get-AzApplicationGatewayAvailableWafRuleSets
as per what is indicative to a users WAF Policy and managed rulesets within their given subscription within Azure. #>

Connect-AzAccount
Get-AzSubscription
Set-AzContext -Subscription 'Please enter name of subscription here'
$AppGW = Get-AzApplicationGateway #Will be able to view all AppGW within selected subscription
$WAFConfig = $AppGW.WebApplicationFirewallConfigurationFirewallPolicy #Will be able to view all firewall policies within AppGW's in subscription

#---------------- Parsed Breakdown to Obtain Target WAF RuleSets for App Gateway---------------------------------------------------------------

$AllOWASPRules = Get-AzApplicationGatewayAvailableWafRuleSets #Will output all avaialable CRS/DRS rulesets within AppGW in chosen subscription
$CSV = $AllOWASPRules | ConvertTo-CSV #Converting System.Object Output into Delimited System String for parsing purposes
$ParsedCSV = $CSV | ConvertFrom-String -Delimiter "RuleSetVersion" #Parsing all outputs to hone in on all OWASP Ruleset Engines as chosen string delimiter
$ObjectLetter = "P" #Parsed entries will always be denoted by the letter 'P' when doing this method of conversion
$ObjectNumber = "2" #Based off of delimiter being RuleSetVersion, entire breakdown of all OWASP Rules Engines now become objects to parse entries by. Please base off of terminal output
$TotalObject = $ObjectLetter + $ObjectNumber #Concatenating the variables $ObjectLetter and $ObjectNumber for next line.. Output will display as 'P2' in this example
$RulesEngine = $ParsedCSV.$TotalObject #Selecting the particular rules engine from available parsed entries
$RuleGroupsInRulesEngine = $ParsedCSV.$TotalObject | ConvertFrom-String -Delimiter "RuleGroupName" #Selecting particular RulesGroup from within Rules Engine through this parse

#Note, if wanting to dive one step further into the parsed output, utilize RuleId as your next delimiter. This will more than likely output more than 50+ objects, where each object property is is the RuleID itself
#Example: $RuleGroupsInRulesEngine = $ParsedCSV.$TotalObject | ConvertFrom-String -Delimiter "RuleId" 

[String]$RuleGroupsInRulesEngine = $RuleGroupsInRulesEngine #Forcing Base Type of Object to convert into a String as opposed to System.Object for next steps
$Revstring = '' #Initializing a new empty string to place filtered output into

#----------------------String Comprehension and Masking Variables for Desired Outputs---------------------------------------------------------

<# In the next several lines, the objective is to mask through entire string saved in variable $RulesGroupsInRulesEngine to
remove unwanted spaces and characters and then saving desired masked output into variable $Revstring #>  

foreach ($letter in $RuleGroupsInRulesEngine[0..$RuleGroupsInRulesEngine.length])`
{
    if ($letter -ne ' ' -and ($letter -ne ('""')) -and ($letter -ne '{' ) -and ($letter -ne ('""') -and ($letter -ne '}')))`
    { $Revstring += $letter }
}

#-----Comparison of characters within string of expected CRS Rules within WAF to that of Results within $RevString---------------------------
<#The purpose of this section is to analyze a character by character string for both output $Revstring and search entry entered
by the user for rulesets or rules they are wanting to search for within particular OWASP CRS rules engines.

Site Reference for all CRS/DRS rules and rulesets managed by Microsoft for WAF and App GW: https://learn.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules?tabs=drs21
This example will search based for particular rules within ruleset for OWASP CRS 3.1 engine#>

$newchanges = [ordered]@{} #Any newly listed RuleGroups changes that do not appear within the already composed list of expected rules will be added here
$ExpectedRules = [ordered]@{} #Initializing Hash Table to place OWASP CRS 3.1 expected rules within
$ExpectedRules = [ordered]@{CRS3_1 = 'General', 'Known-CVES', 'REQUEST-911-METHOD-ENFORCEMENT', 'REQUEST-913-SCANNER-DETECTION', 'REQUEST-920-PROTOCOL-ENFORCEMENT',
    'REQUEST-921-PROTOCOL-ATTACK', 'REQUEST-930-APPLICATION-ATTACK-LFI', 'REQUEST-931-APPLICATION-ATTACK-RFI', 'REQUEST-932-APPLICATION-ATTACK-RCE', 
    'REQUEST-933-APPLICATION-ATTACK-PHP', 'REQUEST-941-APPLICATION-ATTACK-XSS', 'REQUEST-942-APPLICATION-ATTACK-SQLI', 'REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION',
    'REQUEST-944-APPLICATION-ATTACK-SESSION-JAVA,'
} #Hard-coded example reviewing all RuleGroups in OWASP CRS 3.1 Rules Engine

#NOTE: Repeat the same steps for RuleID where you add them as a key value pair within the ordered dictionary $ExpectedRules. RuleID being the key, all of the RuleID numbers for the subject OWASP CRS Rules Engine being the values added to that key.
<#NOTE: For OWASP CRS 3.1 and 3.2, if going with Rule ID approach, there will be hundreds of Rule ID's. Rather than hard code, it will be beneficial to obtain
            all of the values for RuleID's via API Call, Bulk Copy, or via imported from a reference file #>
   

#------------------- ForEach Loop Comparison of all String Characters within ExpctedRules vs. What Is Comping from API output-----------------

#Need to create a loop to compare the characters within the dictionary, index by index to see if in overall rules group engine
<# If all the characters within the string value of the dictionary index for CRS key appear to be in the overall characters of the 
    $Revstring, then, there aren't any new changes to be noted and added within variable $newchangesarr. #>


foreach ($ValueWord in $ExpectedRules["CRS3_1"][0..$ExpectedRules["CRS3_1"].length]) {
    foreach ($ValueLetter in $ValueWord[0..$ValueWord.length]) {
        if ($Revstring[0..$Revstring.length] -NotContains $ValueLetter) {
            $newchanges['CRS3_1'] += $ValueLetter
        }
    }
    if ($ValueWord.length) {
        $newchanges['CRS3_1'] += ','
    }
}
#------------------------Saving Stored Results into CSV File with Relative File Path on Desktop--------------------------------------------------

$obj_list = $newchanges['CRS3_1'] | Select-Object @{Name='Unknown CRS Rules';Expression={$_}} #Creating custom object to be saved for CSV file, column being name 'Uknown CRS Rules'. Note, by default without this, only object of a string property is length, so you would not get desired output, which is the value of the string itself.
$obj_list | Export-Csv .\Desktop\'AllCRS.csv' #Saving findings to CSV file named AllCRS.csv, please feel free to change to desired liking.

