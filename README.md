# Set-RoleGroupMembers
This script automates the population of members from one group as members on CUSTOM Exchange Online Role Groups.  

This has been created with the primary goal of allowing scoped administrators to manage Exchange permissions on a subset of users and groups.  

```powershell
Set-RoleGroupMembers -OwnerSourceGroup "<string[ObjectID]>" -RoleGroupsIdentity "<Array[GUID]>"  -DifferentialScope "Int[Number]" -AutomationPSCredential "<string[Cred]>"
```

### Examples
```powershell
Set-AzureGroupOwners -OwnerSourceGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupsIdentity '0e55190c-73ee-e811-80e9-005056a31be6'
```
In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role group '0e55190c-73ee-e811-80e9-005056a31be6'


```powershell
Set-AzureGroupOwners -OwnerSourceGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupsIdentity "0e55190c-73ee-e811-80e9-005056a31be6","0e55190c-73ee-e811-80e9-005056a3" -DifferentialScope 20
```
In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role groups '0e55190c-73ee-e811-80e9-005056a31be6' & '0e55190c-73ee-e811-80e9-005056a3' while allowing 20 changes to group membership.

```powershell
Set-AzureGroupOwners -OwnerSourceGroup [GUID] -RoleGroupsIdentity [GUID] -EXOAutomationCertificate EXOAppCert -EXOAppId [GUID] -EXOOrganization contso.onmicrosoft.com -AzureADAutomationCertificate AzureADAppCert -AzureADAppId [GUID] -AzureADTenantId [GUID]
```
In this example the script uses App-only 'Modern' authentication for access to Exchange Online and Azure AD. This will be the only support way to run unattended scripts into the future. 

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
This script automates the population of members from one group as members on CUSTOM Exchange Role Groups.  

.DESCRIPTION
This has been created with the primary goal of allowing scoped administrators to manage Exchange permissions on a subset of users.  

## Set-RoleGroupMembers [-OwnerSourceGroup <string[ObjectID]>] [-RoleGroupsIdentity <Array[GUID]>] 

.PARAMETER OwnerSourceGroup
The OwnerSourceGroup parameter details the ObjectId of the Azure Group which contains all the desired owners as members of one group.

.PARAMETER RoleGroupsIdentity
The RoleGroupsIdentity parameter specifies the role groups whose membership you want to modify. 

.PARAMETER DifferentialScope
The DifferentialScope parameter defines how many objects can be added or removed from the UserGroups in a single operation of the script. The goal of this setting is throttle bulk changes to limit the impact of misconfiguration by an administrator. What value you choose here will be dictated by your userbase and your script schedule. The default value is set to 10 Objects. 

.PARAMETER AutomationPSCredential
 The AutomationPSCredential parameter defines which Azure Automation Cred you would like to use. This is for Basic Auth Requirements consider updating this to use Service Principles instead. EXO expires this in Mid 2021. 

.PARAMETER EXOAutomationCertificate
 The EXOAutomationCertificate parameter defines which Azure Automation certificate you would like to use which grants access to the Exchange Online App. This certificate must be already installed on the automation account in the certificate store.  

.PARAMETER EXOAppId
The EXOAppId parameter identifies the Azure Application ID GUID of the Service Principle Name. Parameter must be used with -AutomationCertificate. 

.PARAMETER EXOOrganization
The CertificateOrganization parameter identifies the tenant Microsoft address. For example 'consto.onmicrosoft.com' Parameter must be used with -EXOAutomationCertificate. 

.PARAMETER AzureADAutomationCertificate
 The EXOAutomationCertificate parameter defines which Azure Automation Certificate you would like to use which grants access to Exchange Online. 

.PARAMETER AzureADAppId
The EXOAppId parameter specifies the application ID of the service principal. Parameter must be used with -AzureADAutomationCertificate. 

.PARAMETER AzureADTenantId
The AzureADTenantId parameter You must specify the TenantId parameter to authenticate as a service principal or when using Microsoft account. Populate by using the Tenant GUID. 


.EXAMPLE
Set-AzureGroupOwners -OwnerSourceGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupsIdentity '0e55190c-73ee-e811-80e9-005056a31be6'

-- SET MEMBERS FOR ROLE GROUPS --

In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role group '0e55190c-73ee-e811-80e9-005056a31be6'

.EXAMPLE
Set-AzureGroupOwners -OwnerSourceGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupsIdentity "0e55190c-73ee-e811-80e9-005056a31be6","0e55190c-73ee-e811-80e9-005056a3" -DifferentialScope 20

-- SET MEMBERS FOR 2 ROLE GROUPS & INCREASE DIFFERENTIAL SCOPE TO 20 --

In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role groups '0e55190c-73ee-e811-80e9-005056a31be6' & '0e55190c-73ee-e811-80e9-005056a3' while allowing 20 changes to group membership.

.EXAMPLE
Set-AzureGroupOwners -OwnerSourceGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupsIdentity "0e55190c-73ee-e811-80e9-005056a31be6","0e55190c-73ee-e811-80e9-005056a3" -DifferentialScope 20

-- SET MEMBERS FOR 2 ROLE GROUPS & INCREASE DIFFERENTIAL SCOPE TO 20 --

In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role groups '0e55190c-73ee-e811-80e9-005056a31be6' & '0e55190c-73ee-e811-80e9-005056a3' while allowing 20 changes to group membership.

.EXAMPLE
Set-AzureGroupOwners -OwnerSourceGroup [GUID] -RoleGroupsIdentity [GUID] -EXOAutomationCertificate EXOAppCert -EXOAppId [GUID] -EXOOrganization contso.onmicrosoft.com -AzureADAutomationCertificate AzureADAppCert -AzureADAppId [GUID] -AzureADTenantId [GUID]

-- USE APP AUTH TO SET MEMBERS FOR 2 ROLE GROUPS --

In this example the script uses App-only 'Modern' authentication for access to Exchange Online and Azure AD. This will be the only support way to run unattended scripts into the future. 


.LINK

Understanding Management Role Groups - https://docs.microsoft.com/en-us/exchange/understanding-management-role-groups-exchange-2013-help 

Log Analytics Workspace - https://docs.microsoft.com/en-us/azure/azure-monitor/learn/quick-create-workspace

App-only authentication for unattended scripts in the EXO V2 module - https://docs.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps

.NOTES
This function requires that you have already created your Azure AD Groups and Role Groups.

We do not recommend using this script with any Default Role Groups such as 'Help Desk' or 'Compliance Management' as this script may change membership for system accounts used by the compliance centre.

Use Get-RoleGroup | ft Name,ExchangeObjectId to obtain the GUID information for your role group

App Only Auth requires registering the Azure Application along with installing the EXO V2 module and required certificates. 

Please note, when using Azure Automation with more than one user group the array should be set to JSON for example ['ObjectID','ObjectID']

We used AzureADPreview 2.0.2.89 when testing this script. 

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
1.0.1 20191001 - CGarvin - Changed variable $OwnerSourceGroup from String type to $OwnerSourceGroups of Array type for maximum flexibility.
1.0.2 20191021 - JBines - [BUGFIX] Added Select-Object -Unique on the $RoleGroupsIdentity Array.
1.0.3 20210106 - JBINES - [Feature] Added support for the use of Service Principles using Certificates based authenication for Exchange and Azure AD. Also updated AzureADPreview to 2.0.2.89

[TO DO LIST / PRIORITY]
#>
```
