Configuration hardening {

param
       (
       # Target nodes to apply the configuration
       [string[]]$NodeName = 'localhost'
       )
    # Import the module that defines custom resources
    [Parameter(Mandatory)]
    [string] $DomainName,
    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential] $AdminCredentials,
    [Parameter(Mandatory)]
    [string] $DomainNetBiosName,
    [string] $LocalAdministratorName,
    [Parameter(Mandatory)]
    [string] $softwareURI,
    [string] $softwareSasToken
  

  Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
  Import-DscResource -ModuleName 'xComputerManagement'
  
  
  Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 30720

  [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetBiosName}\$($AdminCredentials.UserName)", $AdminCredentials.Password)
  [System.Management.Automation.PSCredential]$LocalAdmin = New-Object System.Management.Automation.PSCredential ($LocalAdministratorName, (ConvertTo-SecureString (New-Password) -AsPlain -Force))
Node $NodeName
    {
       Registry 'DisableRunAs' {
           Ensure    = 'Present'
           Key       = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WinRM\Service'
           ValueName = 'DisableRunAs'
           ValueType = 'DWord'
           ValueData = '1'
       }
       WindowsFeature 'Telnet-Client' {
           Name   = 'Telnet-Client'
           Ensure = 'Present'
       }
       Registry 'AdmPwdEnabled' {
           Ensure    = 'Present'
           Key       = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft Services\AdmPwd'
           ValueName = 'AdmPwdEnabled'
           ValueType = 'DWord'
           ValueData = '1'
       }
  
  {
    LocalConfigurationManager 
    {
      ConfigurationMode = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }

    xScript TurnOffFirewall
    {
      GetScript = {@{}}
      TestScript = {
        $Result = Get-NetFirewallProfile | Where-Object {$_.Enabled -eq $True}
        if($Result) { Return $False } else { Return $True }
      }
      SetScript = {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
      }
    }

    xRegistry DisableIPv6 {
      Key = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
      ValueName = "DisabledComponents"
      Ensure = "Present"
      ValueData = 255
      ValueType = "DWord"
      Force = $true
    }


    }   
    }
}
