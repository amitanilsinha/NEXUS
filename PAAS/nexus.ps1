Configuration Installartifactory {   
    Node localhost
     { 
     
        Script DisableFirewall 
        {
            GetScript = {
                @{
                    GetScript = $GetScript
                    SetScript = $SetScript
                    TestScript = $TestScript
                    Result = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                }
            }
        
            SetScript = {
                Set-NetFirewallProfile -All -Enabled False -Verbose
            }
        
            TestScript = {
                $Status = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                $Status -eq $True
            }
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
