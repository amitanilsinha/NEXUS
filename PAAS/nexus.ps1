Configuration Installartifactory {   
    
	Param(
    [Parameter(Mandatory)]
    [string] $DomainName,
    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential] $AdminCredentials,
    [Parameter(Mandatory)]
    [string] $DomainNetBiosName,
    [string] $LocalAdministratorName,
    [Parameter(Mandatory)]
  )

  Import-DscResource -ModuleName xComputerManagement
  Import-DscResource -ModuleName xPSDesiredStateConfiguration
 
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
	
      Script Download-Software {  
        GetScript = {  
          @{Result = Test-Path 'D:\nexus-3.14.0-04-win64.zip'}
          @{Result = Test-Path 'D:\jre-8u191-windows-x64.exe'}  
        }  
        SetScript = { 
          Enable-PSRemoting -Force
          Invoke-WebRequest -Uri 'https://sonatype-download.global.ssl.fastly.net/repository/repositoryManager/3/nexus-3.14.0-04-win64.zip' -OutFile 'D:\nexus-3.14.0-04-win64.zip'  
          Invoke-WebRequest -Uri 'https://csgdfe49495dc73x47efxabf.blob.core.windows.net/grt/jre-8u191-windows-x64.exe' -OutFile 'D:\jre-8u191-windows-x64.exe'
          Unblock-File -Path 'D:\jre-8u191-windows-x64.exe'
          Unblock-File -Path 'D:\nexus-3.14.0-04-win64.zip'  
            
        }  
        TestScript = {  
          Test-Path 'D:\jre-8u191-windows-x64.exe'
          Test-Path 'D:\nexus-3.14.0-04-win64.zip'  
        }   
      } 
      Archive Uncompress {  
        Ensure = 'Present'  
        Path = 'D:\artifactory-oss-6.5.2.zip'  
        Destination = 'D:\'  
        DependsOn = '[Script]Download-Software'  
      }
      Archive nexus {  
        Ensure = 'Present'  
        Path = 'D:\nexus-3.14.0-04-win64.zip'  
        Destination = 'D:\'  
        DependsOn = '[Script]Download-Software'  
      }
      Package InstallExe
      {
          Ensure          = "Present"
          Name            = "Install Java"
          Path            = "D:\jre-8u191-windows-x64.exe"
          Arguments       = '/s REBOOT=0 SPONSORS=0 REMOVEOUTOFDATEJRES=0 INSTALL_SILENT=1 AUTO_UPDATE=0 EULA=0 /l*v "C:\Windows\Temp\jreInstaller.exe.log"'
          ProductId       = ''
          DependsOn       = '[Script]Download-Software'
      }
      Package Installnexus
      {
          Ensure          = "Present"
          Name            = "Install nexus"
          Path            = "D:\nexus-3.14.0-04\bin\nexus.exe"
          Arguments       = '/run'
          ProductId       = ''
          DependsOn       = '[Script]Download-Software'
      }
    }  
}
