Configuration JumpServer
{
  Param(
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
  )

  Import-DscResource -ModuleName xComputerManagement
  Import-DscResource -ModuleName xPSDesiredStateConfiguration
  Import-DscResource -ModuleName EY
  Import-DscResource -ModuleName AuditPolicyDsc
  Import-DscResource -ModuleName SecurityPolicyDsc

  Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 30720

  [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetBiosName}\$($AdminCredentials.UserName)", $AdminCredentials.Password)
  [System.Management.Automation.PSCredential]$LocalAdmin = New-Object System.Management.Automation.PSCredential ($LocalAdministratorName, (ConvertTo-SecureString (New-Password) -AsPlain -Force))

  Node localhost
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

    xScript Disable6to4 {
      GetScript = {
        $result = (Get-Net6to4Configuration).State -eq 'Disabled'
        return @{"Result"=$result}
      }
      TestScript = {
        return (Get-Net6to4Configuration).State -eq 'Disabled'
      }
      SetScript = {
        Set-Net6to4Configuration -State Disabled
        $global:DSCMachineStatus = 1
      }
      DependsOn = "[xRegistry]DisableIPv6"
    }

    xComputer DomainJoin
    {
      Name = $env:COMPUTERNAME
      DomainName = $DomainName
      Credential = $DomainCreds
      DependsOn = "[xScript]Disable6to4"
    }

    Script ForceDNSRegistration {
      DependsOn = "[xComputer]DomainJoin"
      GetScript = {
        $Result=(-not ([bool](Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'" | where { ($_.FullDNSRegistrationEnabled -ne "True") -OR ($_.DomainDNSRegistrationEnabled -ne "True") })))
        return @{"Result"=$Result}
      }
      TestScript = {
        $Result=(-not ([bool](Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'" | where { ($_.FullDNSRegistrationEnabled -ne "True") -OR ($_.DomainDNSRegistrationEnabled -ne "True") })))
        return $Result
      }
      SetScript = {
        Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'" | foreach-object { $_.SetDynamicDNSRegistration($true,$true) }
        Start-Process -FilePath "$Env:SystemRoot\System32\ipconfig.exe" -ArgumentList "/registerdns" -Wait
      }
    }

    xWindowsFeature DnsTools
		{
			Ensure = "Present"
      Name = "RSAT-DNS-Server"
      DependsOn = "[xComputer]DomainJoin"
    }

    xWindowsFeature ADAdminCenter
    {
      Ensure = "Present"
      Name = "RSAT-AD-AdminCenter"
      DependsOn = "[xComputer]DomainJoin"
    }

    xWindowsFeature ADDSTools 
    {
      Ensure = "Present"
      Name = "RSAT-ADDS-Tools"
      DependsOn = "[xComputer]DomainJoin"
    }

    EY_W2K16_Member_CoreAgents InstallCoreAgents {
      DependsOn = "[Script]ForceDNSRegistration"
      SoftwareRepoUri = $softwareURI
      SoftwareRepoSASToken = $softwareSasToken
    }

    EY_W2K16_Member_ExtraSettings ApplyAdditionalSettings {
      DependsOn = "[EY_W2K16_Member_CoreAgents]InstallCoreAgents"
    }
  }
}

Function New-Password
{
  Param(
    [int]$Length = 24
  )

  $ascii = @('!','#','%','&','(',')','*','+','-','.','/','0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\',']','_','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{','|','}')

  For($loop=1;$loop -le $Length;$loop++)
  {
    $TempPassword += ($ascii | Get-Random)
  }

  return $TempPassword
}
