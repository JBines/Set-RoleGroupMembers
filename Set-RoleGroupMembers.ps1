<# 
.SYNOPSIS
This script automates the population of members from one group as members on CUSTOM Exchange Role Groups.  

.DESCRIPTION
This has been created with the primary goal of allowing scoped administrators to manage Exchange permissions on a subset of users.  

## Set-RoleGroupMembers [-OwnerSourceGroup <string[ObjectID]>] [-RoleGroupsIdentity <Array[GUID]>] [-EXOOrganization <string[*.onmicrosoft.com]>] [-EXOAutomationPSConnection <string[Name]>] [-AADAutomationPSConnection <string[Name]>] 

.PARAMETER OwnerSourceGroup
The OwnerSourceGroup parameter details the ObjectId of the Azure Group which contains all the desired owners as members of one group.

.PARAMETER RoleGroupsIdentity
The RoleGroupsIdentity parameter specifies the role groups whose membership you want to modify. This can be found by running Get-RoleGroup <Name> | FL Name,*guid*

.PARAMETER DifferentialScope
The DifferentialScope parameter defines how many objects can be added or removed from the UserGroups in a single operation of the script. The goal of this setting is throttle bulk changes to limit the impact of misconfiguration by an administrator. What value you choose here will be dictated by your userbase and your script schedule. The default value is set to 10 Objects. 

.PARAMETER EXOOrganization
The CertificateOrganization parameter identifies the tenant Microsoft address. For example 'consto.onmicrosoft.com' Parameter must be used with -EXOAutomationPSCertificate & -EXOAutomationPSConnection. 

.PARAMETER EXOAutomationPSConnection
 The AutomationPSConnection parameter defines the connection details such as AppID, Tenant ID. Parameter must be used with -EXOAutomationPSCertificate & -EXOOrganization.

.PARAMETER AADAutomationPSConnection
 The AutomationPSConnection parameter defines the connection details such as AppID, Tenant ID. Parameter must be used with -AADAutomationPSCertificate.

.EXAMPLE
Set-RoleGroupMembers -OwnerSourceGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupsIdentity '0e55190c-73ee-e811-80e9-005056a31be6'

-- SET MEMBERS FOR ROLE GROUPS --

In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role group '0e55190c-73ee-e811-80e9-005056a31be6'

.EXAMPLE
Set-RoleGroupMembers -OwnerSourceGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupsIdentity "0e55190c-73ee-e811-80e9-005056a31be6","0e55190c-73ee-e811-80e9-005056a3" -DifferentialScope 20

-- SET MEMBERS FOR 2 ROLE GROUPS & INCREASE DIFFERENTIAL SCOPE TO 20 --

In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role groups '0e55190c-73ee-e811-80e9-005056a31be6' & '0e55190c-73ee-e811-80e9-005056a3' while allowing 20 changes to group membership.

.EXAMPLE
.\Set-AzureGroupOwners.ps1 -OwnerSourceGroup '7b7c4926-c6d7-4ca8-9bbf-5965751022c2' -RoleGroupsIdentity "0e55190c-73ee-e811-80e9-005056a31be6","0e55190c-73ee-e811-80e9-005056a3" -DifferentialScope 20

-- SET MEMBERS FOR 2 ROLE GROUPS & INCREASE DIFFERENTIAL SCOPE TO 20 --

In this example the script will add users (members of Group '7b7c4926-c6d7-4ca8-9bbf-5965751022c2') as members to the Role groups '0e55190c-73ee-e811-80e9-005056a31be6' & '0e55190c-73ee-e811-80e9-005056a3' while allowing 20 changes to group membership.

.EXAMPLE
.\Set-AzureGroupOwners.ps1 -OwnerSourceGroup [GUID] -RoleGroupsIdentity [GUID] -EXOOrganization contso.onmicrosoft.com -EXOAutomationPSConnection [Name] -AADAutomationPSConnection [Name]

-- USE APP AUTH TO SET MEMBERS FOR 2 ROLE GROUPS --

In this example the script uses App-only 'Modern' authentication for access to Exchange Online and Azure AD. This will be the only support way to run unattended scripts into the future. 


.LINK

Understanding Management Role Groups - https://docs.microsoft.com/en-us/exchange/understanding-management-role-groups-exchange-2013-help 

App-only authentication for unattended scripts in the EXO V2 module - https://docs.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps

.NOTES
This function requires that you have already created your Azure AD Groups and Role Groups.

We do not recommend using this script with any Default Role Groups such as 'Help Desk' or 'Compliance Management' as this script may change membership for system accounts used by the compliance centre.

Use Get-RoleGroup | ft Name,ExchangeObjectId to obtain the GUID information for your role group

App Only Auth requires registering the Azure Application along with installing the EXO V2 module and required certificates. 

Please note, when using Azure Automation with more than one user group the array should be set to JSON for example ['ObjectID','ObjectID']

We used AzureAD GA Version: 2.0.2.140 when testing this script.


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
1.0.4 20211227 - JBines - [Feature] Added switches for the Get-AutomationConnection and removed extra variables which were needed. Upgraded to AzureAD GA


[TO DO LIST / PRIORITY]
    Migrate to Graph API / MED

#>

Param 
(
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [Array]$OwnerSourceGroups,
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [array]$RoleGroupsIdentity,
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [Int]$DifferentialScope = 10,
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [String]$AutomationPSCredential,
    #[Parameter(ParameterSetName='EXO',Mandatory = $False)]
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [String]$EXOAutomationPSConnection,
    [Parameter(Mandatory = $False)]
    [ValidatePattern('(?i)\S\.onmicrosoft.com$')]
    [ValidateNotNullOrEmpty()]
    [String]$EXOOrganization,
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [String]$AADAutomationPSConnection
)

    #Set VAR
    $counter = 0

# Success Strings
    $sString0 = "OUT-CMDlet:Remove-RoleGroupMember"
    $sString1 = "IN-CMDlet:Add-RoleGroupMember"

    # Info Strings
    $iString0 = "Processing Role Group"

# Warn Strings
    $wString0 = "CMDlet:Measure-Object;No Members found in OwnerSourceGroups"
    $wString1 = "CMDlet:Measure-Object;No Members found in RoleGroup"

# Error Strings

    $eString2 = "Hey! You made it to the default switch. That shouldn't happen might be a null or returned value."
    $eString3 = "Hey! You hit the -DifferentialScope limit of $DifferentialScope. Let's break out of this loop"
    $eString4 = "Hey! Help us out and put some users in the group."

# Debug Strings
    #$dString1 = ""

    #Load Functions

    function Write-Log([string[]]$Message, [string]$LogFile = $Script:LogFile, [switch]$ConsoleOutput, [ValidateSet("SUCCESS", "INFO", "WARN", "ERROR", "DEBUG")][string]$LogLevel)
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

                         if($AutomationPSCredential -or $EXOAutomationPSConnection -or $AADAutomationPSConnection)
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

    #Validate Input Values From Parameter 

    Try{

        If($EXOAutomationPSConnection -and $AADAutomationPSConnection){
            
            #Connect Exchange
            $EXOConnection = Get-AutomationConnection -Name $EXOAutomationPSConnection
            #Connect-ExchangeOnline -CertificateThumbprint $EXOCert.Thumbprint -AppId $EXOAppId -ShowBanner:$false -Organization $EXOCertificateOrganization
            Connect-ExchangeOnline -CertificateThumbprint $EXOConnection.CertificateThumbprint -AppId $EXOConnection.ApplicationId -Organization $EXOOrganization -ShowBanner:$false
            
            #Connect Azure AD
            $AzureADConnection = Get-AutomationConnection -Name $AADAutomationPSConnection
            Connect-AzureAD -TenantId $AzureADConnection.TenantId -ApplicationId $AzureADConnection.ApplicationId -CertificateThumbprint $AzureADConnection.CertificateThumbprint 

        }
        Else
        {
            Remove-Variable EXOAutomationPSConnection
            Remove-Variable AADAutomationPSConnection
            Remove-Variable EXOORGANIZATION
        }

        if ($AutomationPSCredential -and (-not($EXOAutomationPSConnection -and $AADAutomationPSConnection))) {
            
            $Credential = Get-AutomationPSCredential -Name $AutomationPSCredential

            Connect-AzureAD -Credential $Credential
            
            #$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection
            #Import-PSSession $Session -DisableNameChecking -Name ExSession -AllowClobber:$true | Out-Null

            $ExchangeOnlineSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection -Name $ConnectionName 
            Import-Module (Import-PSSession -Session $ExchangeOnlineSession -AllowClobber -DisableNameChecking) -Global

            }
                      
        $objOwnerSourceGroupMembers = @($OwnerSourceGroups | ForEach-Object {Get-AzureADGroupMember -ObjectId $_})

        #Return Only Unique values remove any duplicates
        $OwnerSourceGroupMembers = $objOwnerSourceGroupMembers | Select-Object -Unique

        #Check if Owners Group is $Null
        $OwnerSourceGroupMembersNull = $False
        if($OwnerSourceGroupMembers.count -eq 0){
            $OwnerSourceGroupMembersNull = $True
            If($?){Write-Log -Message $wString0 -LogLevel WARN -ConsoleOutput}
        }
        
        #Create Exchange Role Group Array
        $ExchangeRoleGroups = @()

        if ($RoleGroupsIdentity) {
            
            foreach ($roleGroup in $RoleGroupsIdentity){
                $ExchangeRoleGroups += Get-RoleGroup -Identity $roleGroup -ErrorAction Stop
            }    
        }
        Else{Write-Error "No User Group Found"}
    }
    
    Catch{
    
        $ErrorMessage = $_.Exception.Message
        Write-Error $ErrorMessage 

            If($?){Write-Log -Message $ErrorMessage -LogLevel Error -ConsoleOutput}

        throw $ErrorMessage 
        Break

    }

    foreach($ExchangeRoleGroup in $ExchangeRoleGroups){
        
        Write-Log -Message "$iString0 - $($ExchangeRoleGroup.Name)" -LogLevel INFO -ConsoleOutput

        #Catch bad calls for role group members from dropping members 
        try {
            
            $exchangeRoleGroupMembers = $null
            $exchangeRoleGroupMembers = Get-RoleGroupMember -Identity $ExchangeRoleGroup.GUID.ToString() | Get-User #| ForEach-Object{Get-AzureADUser -SearchString $($_.UserPrincipalName)}
            #Get-RoleGroupMember -Identity $ExchangeRoleGroup.GUID.ToString() | Get-User | ForEach-Object{Get-AzureADUser -SearchString $($_.UserPrincipalName)}
            $exchangeRoleGroupMember = @()
            foreach($objexchangeRoleGroupMembers in $exchangeRoleGroupMembers){

                $exchangeRoleGroupMember += Get-AzureADUser -ObjectId $objexchangeRoleGroupMembers.UserPrincipalName

            }
            
        }
        catch {
            $ErrorMessage = $_.Exception.Message

            If($?){Write-Log -Message $ErrorMessage -LogLevel Error -ConsoleOutput}

            Break
        }

        $exchangeRoleGroupMemberNULL = $False

        if($exchangeRoleGroupMember.count -eq 0){
            $exchangeRoleGroupMemberNULL = $True
            If($?){Write-Log -Message $wString1 -LogLevel WARN -ConsoleOutput}
        }

        switch ($exchangeRoleGroupMemberNULL) {
            {(-not($exchangeRoleGroupMemberNULL))-and(-not($OwnerSourceGroupMembersNull))}{ 
                                                                                    
                                                                                    #Compare Lists and find missing users those who should be removed. 
                                                                                    $assessUsers = Compare-Object -ReferenceObject $OwnerSourceGroupMembers.ObjectID -DifferenceObject $exchangeRoleGroupMember.ObjectId | Where-Object {$_.SideIndicator -ne "=="}
                                                                                    
                                                                                    if($null -ne $assessUsers){

                                                                                        Foreach($objUser in $assessUsers){  

                                                                                            if ($counter -lt $DifferentialScope) {

                                                                                                # <= -eq Add Object
                                                                                                # = -eq Skip
                                                                                                # => -eq Remove Object

                                                                                                Switch ($objUser.SideIndicator) {
                                                                                
                                                                                                    "=>" { 
                                                                                                    
                                                                                                        $objID = $objUser.InputObject
                                                                                                        $objUPN = (Get-AzureADUser -ObjectId $objID).UserPrincipalName 
                                                                                                        $objGroupID = $ExchangeRoleGroup.GUID.ToString()

                                                                                                        try {

                                                                                                            Remove-RoleGroupMember $objGroupID -Member $objUPN -Confirm:$false
                                                                                                            if($?){Write-Log -Message "$sString0;RoleGroup:$($ExchangeRoleGroup.Name);ObjectId:$objID" -LogLevel SUCCESS -ConsoleOutput}
                        
                                                                                                        }
                                                                                                        catch {
                                                                                                            Write-log -Message $_.Exception.Message -ConsoleOutput -LogLevel ERROR
                                                                                                            Break                                                                                   
                                                                                                        }
                                                                                                        
                                                                                                        #Increase the count post change
                                                                                                        $counter++
                                                                                
                                                                                                        $objID = $null
                                                                                                        $objGroupID = $null
                                                                                                        $objUPN = $null
                                                                                                        
                                                                                                            }
                                                                                
                                                                                                    "<=" { 

                                                                                                        $objID = $objUser.InputObject
                                                                                                        $objUPN = (Get-AzureADUser -ObjectId $objID).UserPrincipalName 
                                                                                                        $objGroupID = $ExchangeRoleGroup.GUID.ToString()

                                                                                                        Add-RoleGroupMember $objGroupID -Member $objUPN -Confirm:$false
                                                                                                        if($?){Write-Log -Message "$sString1;RoleGroup:$($ExchangeRoleGroup.Name);ObjectId:$objID" -LogLevel SUCCESS -ConsoleOutput}

                                                                                                        #Increase the count post change
                                                                                                        $counter++
                                                                                
                                                                                                        $objID = $null
                                                                                                        $objGroupID = $null
                                                                                                        $objUPN = $null
                                                                                
                                                                                                            }
                                                                                
                                                                                                    Default {Write-log -Message $eString2 -ConsoleOutput -LogLevel ERROR }
                                                                                                }
                                                                                            }
                                                                                
                                                                                            else {
                                                                                                       
                                                                                                #Exceeded couter limit
                                                                                                Write-log -Message $eString3 -ConsoleOutput -LogLevel ERROR
                                                                                                Break
                                                                                
                                                                                            }  
                                                                                
                                                                                        }
                                                                                    }

                                                                                }
            {($exchangeRoleGroupMemberNULL-and(-not($OwnerSourceGroupMembersNull)))}{ 
                                                                                
                                                                                foreach($objGroupMember in $OwnerSourceGroupMembers){
                                                                                    if ($counter -lt $DifferentialScope) {

                                                                                        $objID = $objGroupMember.ObjectID
                                                                                        $objUPN = (Get-AzureADUser -ObjectId $objID).UserPrincipalName 
                                                                                        $objGroupID = $ExchangeRoleGroup.GUID.ToString()

                                                                                        Add-RoleGroupMember $objGroupID -Member $objUPN -Confirm:$false
                                                                                        if($?){Write-Log -Message "$sString1;RoleGroup:$($ExchangeRoleGroup.Name);ObjectId:$objID" -LogLevel SUCCESS -ConsoleOutput}

                                                                                        #Increase the count post change
                                                                                        $counter++
                                                                
                                                                                        $objID = $null
                                                                                        $objGroupID = $null
                                                                                        $objUPN = $null
                                                                                    }
                                                                                    else {
                                                                                    
                                                                                        #Exceeded couter limit
                                                                                        Write-log -Message $eString3 -ConsoleOutput -LogLevel ERROR
                                                                                        Break
                                                                        
                                                                                    }  
                                                                                }
                                                                            }
            {(-not($exchangeRoleGroupMemberNULL))-and($OwnerSourceGroupMembersNull)}{ 
                                                                                    
                                                                            foreach($objExchangeRoleGroupMember in $exchangeRoleGroupMember){
                                                                                if ($counter -lt $DifferentialScope) {
                                                                                
                                                                                    $objID = $objExchangeRoleGroupMember.ObjectID
                                                                                    $objUPN = $objExchangeRoleGroupMember.UserPrincipalName 
                                                                                    $objGroupID = $ExchangeRoleGroup.GUID.ToString()

                                                                                    try {

                                                                                        Remove-RoleGroupMember $objGroupID -Member $objUPN -Confirm:$false
                                                                                        if($?){Write-Log -Message "$sString0;RoleGroup:$($ExchangeRoleGroup.Name);ObjectId:$objID" -LogLevel SUCCESS -ConsoleOutput}
    
                                                                                    }
                                                                                    catch {
                                                                                        Write-log -Message $_.Exception.Message -ConsoleOutput -LogLevel ERROR
                                                                                        Break                                                                                   
                                                                                    }
                                                                
                                                                                    #Increase the count post change
                                                                                    $counter++
                                                                                    
                                                                                    $objID = $null
                                                                                    $objGroupID = $null
                                                                                    $objUPN = $null

                                                                                }

                                                                                else {
                                                                                
                                                                                    #Exceeded couter limit
                                                                                    Write-log -Message $eString3 -ConsoleOutput -LogLevel ERROR
                                                                                    Break
                                                                    
                                                                                }      
                                                                            }
                                                                        }
            Default {Write-Log -Message $eString4 -LogLevel ERROR -ConsoleOutput}
        }
    }

if ($EXOAutomationCertificate -or $AzureADAutomationCertificate) {
    
    #Invoke-Command -Session $ExchangeOnlineSession -ScriptBlock {Remove-PSSession -Session $ExchangeOnlineSession}

    Disconnect-AzureAD -Confirm:$false
    Disconnect-ExchangeOnline -Confirm:$false
}
