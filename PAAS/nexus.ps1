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
      
  #Install the IIS Role
          WindowsFeature IIS
         {
          Ensure = “Present”
          Name = “Web-Server”
         }

         #Install ASP.NET 4.5
         WindowsFeature ASP
         {
          Ensure = “Present”
          Name = “Web-Asp-Net45”
         }

         WindowsFeature WebServerManagementConsole
         {
          Name = "Web-Mgmt-Console"
          Ensure = "Present"
         }
         File devfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\dev'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }
         File uatfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\uat'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }  
         File prodfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\prod'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }

          xWebsite DevWebsite
         {
            Ensure          = 'Present'
            Name            = $WebSitePrefix + '-dev'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\dev'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = $DevPublicDNS
                                 }

                                )
            DependsOn       = '[File]devfolder'

         } 
         xWebsite UatWebsite
         {
            Ensure          = 'Present'
            Name            = $WebSitePrefix +'-uat'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\uat'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = $UatPublicDNS
                                 }

                                )
            DependsOn       = '[File]uatfolder'
         }

         xWebsite prodWebsite
         {
            Ensure          = 'Present'
            Name            = $WebSitePrefix +'-prod'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\prod'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = $ProdPublicDNS
                                 }

                                )
            DependsOn       = '[File]prodfolder'
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
