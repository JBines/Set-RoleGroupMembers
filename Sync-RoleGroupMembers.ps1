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

param 
(
  [Parameter(Mandatory = $true)]  [ValidateNotNullOrEmpty()]  [array] $GroupIds,
  [Parameter(Mandatory = $true)]  [ValidateNotNullOrEmpty()]  [array] $RoleGroupIds,
  [Parameter(Mandatory = $false)] [ValidateNotNullOrEmpty()]  [int]   $DifferentialScope = 10,
  [Parameter(Mandatory = $false)] [ValidateNotNullOrEmpty()]  [bool]   $EnableManagedIdentity = $false,
  [Parameter(Mandatory = $true)]  [ValidatePattern('(?i)\S\.onmicrosoft.com$')][string]$EXOOrganization
)
    #Load Functions
    function Write-Log([string[]]$Message, [string]$LogFile = $Script:LogFile, [bool]$ConsoleOutput = $true, [ValidateSet("SUCCESS", "INFO", "WARN", "ERROR", "DEBUG")][string]$LogLevel)
    {
           $Message = $Message + $Input
           If (!$LogLevel) { $LogLevel = "INFO" }
           switch ($LogLevel)
           {
                  SUCCESS { $Color = "Green" }
                  INFO { $Color = "White" }
                  WARN { $Color = "Yellow" }
                  ERROR { $Color = "Red" }
                  DEBUG { $Color = "Gray" }
           }
           if ($Message -ne $null -and $Message.Length -gt 0)
           {
                  $TimeStamp = [System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
                  if ($LogFile -ne $null -and $LogFile -ne [System.String]::Empty)
                  {
                         Out-File -Append -FilePath $LogFile -InputObject "[$TimeStamp] [$LogLevel] $Message"
                  }
                  if ($ConsoleOutput -eq $true)
                  {
                         Write-Host "[$TimeStamp] [$LogLevel] :: $Message" -ForegroundColor $Color

                         if($EnableManagedIdentity)
                         {
                         Write-Output "[$TimeStamp] [$LogLevel] :: $Message"
                    } 
                  }
                  if($LogLevel -eq "ERROR")
                    {
                        Write-Error "[$TimeStamp] [$LogLevel] :: $Message"
                    }
           }
    }

    Function Test-CommandExists 
    {

     Param ($command)

         $oldPreference = $ErrorActionPreference

         $ErrorActionPreference = 'stop'

         try {if(Get-Command $command){RETURN $true}}

         Catch {Write-Host "$command does not exist"; RETURN $false}

         Finally {$ErrorActionPreference=$oldPreference}

    } #end function test-CommandExists

    function Stop-Script([int]$ExitCode) {
      Disconnect-MgGraph | Out-Null
      Disconnect-ExchangeOnline -Confirm:$false
      
      exit $ExitCode
    }

### START SCRIPT ###

try {
  If($EnableManagedIdentity){
    Connect-ExchangeOnline -Organization $EXOOrganization -ShowBanner:$false -ManagedIdentity
    Connect-MgGraph -NoWelcome -Identity
    Write-Log -LogLevel SUCCESS -Message "Connected to Exchange Online and MgGraph"
  }
}

catch {
  Write-Log -LogLevel ERROR -Message $_.Exception.Message
  Stop-Script 1
}

#Check cred Account has all the required permissions 
If(Test-CommandExists Get-MgGroupMember,Get-MgUser,Get-RoleGroup,Add-RoleGroupMember,Remove-RoleGroupMember){

  Write-Log -Message "Correct RBAC Access Confirmed" -LogLevel DEBUG

}

Else {Write-Log -Message "Script requires a higher level of access! You are missing at least one required CMDlet." -LogLevel ERROR; Break}

$GroupMembers = foreach ($GroupId in $GroupIds) { Get-MgGroupMember -GroupId $GroupId -All }
$GroupMembers = $GroupMembers | Select-Object Id -Unique

$RoleGroups = foreach ($RoleGroupId in $RoleGroupIds) { Get-RoleGroup -Identity $RoleGroupId -ErrorAction Stop }
if (!$RoleGroups) { Write-Log -LogLevel ERROR -Message "No Exchange Online Role Groups Found"; Stop-Script 1 }
if (!$GroupMembers) { $GroupMembers = @{ Id = @() }; Write-Log -LogLevel WARN -Message "No members in Group Members found"}

$DifferentialCounter = 0
foreach ($RoleGroup in $RoleGroups) {
  Write-Log -LogLevel INFO -Message "Processing Role Group: $($RoleGroup.Name)" 

  # get user id from azure ad
  $RoleGroupMembers = Get-RoleGroupMember -Identity $RoleGroup.Guid.ToString() -ErrorAction Stop
  $RoleGroupUsers = foreach ($RoleGroupMember in $RoleGroupMembers) { Get-MgUser -UserId $RoleGroupMember.ExternalDirectoryObjectId -ErrorAction Stop }

  if (!$RoleGroupUsers) { $RoleGroupUsers = @{ Id = @() }; Write-Log -LogLevel WARN -Message "      No members found in that Role Group" }

  $AssessUsers = Compare-Object -ReferenceObject $GroupMembers.Id -DifferenceObject $RoleGroupUsers.Id

  foreach ($AssessUser in $AssessUsers) {
    if ($DifferentialCounter -eq $DifferentialScope) { Write-Log -LogLevel ERROR -Message "      Differential scope reached, exiting..."; Stop-Script 1 }

    $UserId = $AssessUser.InputObject
    $UserUPN = (Get-MgUser -UserId $UserId).UserPrincipalName

    switch ($AssessUser.SideIndicator) {
      # user is only in azure group
      "<=" {
        try {
          Add-RoleGroupMember -Identity $RoleGroup -Member $UserUPN -Confirm:$false
          Write-Log -LogLevel SUCCESS -Message "IN-CMDlet: Add-RoleGroupMember; RoleGroup:$($RoleGroup.Name); User: $UserUPN"
        }
        catch { Write-Log -LogLevel ERROR -Message $_.Exception.Message }
      }
      # user is only in role group
      "=>" {
        try {
          Remove-RoleGroupMember -Identity $RoleGroup -Member $UserUPN -Confirm:$false
          Write-Log -LogLevel SUCCESS -Message "OUT-CMDlet: Remove-RoleGroupMember; RoleGroup:$($RoleGroup.Name); User: $UserUPN"
        }
        catch { Write-Log -LogLevel ERROR -Message $_.Exception.Message }
      }
    }
    $DifferentialCounter++
  }
}

#Stop-Script 0
