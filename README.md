# Sync-RoleGroupMembers
This script automates the population of members from one group as members on CUSTOM Exchange Online Role Groups.  

This has been created with the primary goal of allowing scoped administrators to manage Exchange permissions on a subset of users and groups.  

```powershell
## Sync-RoleGroupMembers.ps1 [-GroupIds <Array[ObjectID]>] [-RoleGroupIds <Array[GUID]>] [-EXOOrganization <string[*.onmicrosoft.com]>] [-EnableManagedIdentity <BOOL[True|False]>]

```

### Examples
```powershell
Sync-RoleGroupMembers.ps1 -GroupIds '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupIds '0e55190c-73ee-e811-80e9-005056a31be6'
```
In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role group '0e55190c-73ee-e811-80e9-005056a31be6'


```powershell
Sync-RoleGroupMembers.ps1 -GroupIds '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupIds "0e55190c-73ee-e811-80e9-005056a31be6","0e55190c-73ee-e811-80e9-005056a3" -DifferentialScope 20
```
In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role groups '0e55190c-73ee-e811-80e9-005056a31be6' & '0e55190c-73ee-e811-80e9-005056a3' while allowing 20 changes to group membership.

 
### Final Notes
This function requires that you have already created your Azure AD Groups and Role Groups.

We do not recommend using this script with any Default Role Groups such as 'Help Desk' or 'Compliance Management' as this script may change membership for system accounts used by the compliance centre.

Use Get-RoleGroup | ft Name,ExchangeObjectId to obtain the GUID information for your role group

App Only Auth requires registering the Azure Application along with installing the EXO V2 module and required certificates. 

Please note, when using Azure Automation with more than one user group the array should be set to JSON for example ['ObjectID','ObjectID']

We used AzureADPreview 2.0.2.89 when testing this script. 

```powershell
<#
.SYNOPSIS
This script automates the population of members from Entra groups as members on Exchange Online Role Groups.  

.DESCRIPTION
This has been created with the primary goal of allowing scoped administrators to manage Exchange permissions on a subset of users.  

## Sync-RoleGroupMembers [-GroupIds <Array[ObjectID]>] [-RoleGroupIds <Array[GUID]>] [-EXOOrganization <string[*.onmicrosoft.com]>] [-EnableManagedIdentity <BOOL[True|False]>]

.PARAMETER GroupIds
The GroupIds parameter details the ObjectId of the Azure Group which contains all the desired owners as members of one group.

.PARAMETER RoleGroupIds
The RoleGroupIds parameter specifies the role groups whose membership you want to modify. This can be found by running Get-RoleGroup <Name> | FL Name,*guid*

.PARAMETER DifferentialScope
The DifferentialScope parameter defines how many objects can be added or removed from the Role Groups in a single operation of the script. The goal of this setting is throttle bulk changes to limit the impact of misconfiguration by an administrator. What value you choose here will be dictated by your userbase and your script schedule. The default value is set to 10 Objects. 

.PARAMETER EXOOrganization
The EXOOrganization parameter identifies the tenant Microsoft address. For example 'consto.onmicrosoft.com'. 

.PARAMETER EnableManagedIdentity
The EnableManagedID parameter connects to the Exchange Online and Graph Module via a Managed Identity. Without this switch the script will require manually connecting to these modules.

.PARAMETER EXOAutomationPSConnection [DISCONTINUED]
 The AutomationPSConnection parameter defines the connection details such as AppID, Tenant ID. Parameter must be used with -EXOAutomationPSCertificate & -EXOOrganization.

.PARAMETER AADAutomationPSConnection [DISCONTINUED]
 The AutomationPSConnection parameter defines the connection details such as AppID, Tenant ID. Parameter must be used with -AADAutomationPSCertificate.

.EXAMPLE
Sync-RoleGroupMembers -GroupIds '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupIds '0e55190c-73ee-e811-80e9-005056a31be6'

-- SET MEMBERS FOR ROLE GROUPS --

In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role group '0e55190c-73ee-e811-80e9-005056a31be6'

.EXAMPLE
Sync-RoleGroupMembers -GroupIds '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupIds "0e55190c-73ee-e811-80e9-005056a31be6","0e55190c-73ee-e811-80e9-005056a3" -DifferentialScope 20

-- SET MEMBERS FOR 2 ROLE GROUPS & INCREASE DIFFERENTIAL SCOPE TO 20 --

In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role groups '0e55190c-73ee-e811-80e9-005056a31be6' & '0e55190c-73ee-e811-80e9-005056a3' while allowing 20 changes to group membership.

.LINK

Understanding Management Role Groups - https://docs.microsoft.com/en-us/exchange/understanding-management-role-groups-exchange-2013-help 

App-only authentication for unattended scripts in the EXO V3 module - https://docs.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps

.NOTES
This function requires that you have already created your Entra ID Groups and Role Groups.

We do not recommend using this script with any Default Role Groups such as 'Help Desk' or 'Compliance Management' as this script may change membership for system accounts used by the defender portal.

Use Get-RoleGroup | ft Name,ExchangeObjectId to obtain the GUID information for your role group

App Only Auth requires registering the Azure Application along with installing the EXO V3 module and required certificates. 

Please note, when using Azure Automation Runbooks with more than one group the array should be set to JSON for example ['ObjectID','ObjectID']


[AUTHOR]
Joshua Bines, Consultant

Find me on:
* Web:     https://theinformationstore.com.au
* LinkedIn:  https://www.linkedin.com/in/joshua-bines-4451534
* Github:    https://github.com/jbines
  
[VERSION HISTORY / UPDATES]
0.0.1 20190312 - JBINES - Created the bare bones
0.0.2 20190314 - JBines - [BUGFIX] Removed Secure String and Begin Process End as it is not supported in azure automation. 
                        - [Feature] Added a write-output when AutomationPSCredential is using in the write-log function
1.0.0 20190314 - JBines - [MAJOR RELEASE] Other than that it works like a dream... 
1.0.1 20191001 - CG     - Changed variable $OwnerSourceGroup from String type to $OwnerSourceGroups of Array type for maximum flexibility.
1.0.2 20191021 - JBines - [BUGFIX] Added Select-Object -Unique on the $RoleGroupsIdentity Array.
1.0.3 20210106 - JBINES - [Feature] Added support for the use of Service Principles using Certificates based authenication for Exchange and Azure AD. Also updated AzureADPreview to 2.0.2.89
1.0.4 20211227 - JBines - [Feature] Added switches for the Get-AutomationConnection and removed extra variables which were needed. Upgraded to AzureAD GA.
1.0.5 20230816 - JBines - [Feature] Added support for EXO managed identity.
2.0.0 20240603 - JBines - [MAJOR RELEASE] Changed from Azure AD to MG Graph Module. Note now requires the use of managed identity and removed some of the complexity.

[TO DO LIST / PRIORITY]
#>
```
