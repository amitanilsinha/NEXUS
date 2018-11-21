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
      
      Configuration ContosoWebsite
{
  
  {
   ## IIS URL Rewrite module download and install
		Package UrlRewrite
		{
			#Install URL Rewrite module for IIS
			DependsOn = "[WindowsFeature]WebServerRole"
			Ensure = "Present"
			Name = "IIS URL Rewrite Module 2"
			Path = "http://download.microsoft.com/download/6/7/D/67D80164-7DD0-48AF-86E3-DE7A182D6815/rewrite_2.0_rtw_x64.msi"
			Arguments = "/quiet"
			ProductId = "EB675D0A-2C95-405B-BEE8-B42A65D23E11"
		}

		# Download and install the web site and content
		Script DeployWebPackage
		{
			GetScript = {@{Result = "DeployWebPackage"}}
			TestScript = {$false}
			SetScript ={
				[system.io.directory]::CreateDirectory("C:\WebApp")
				$dest = "C:\WebApp\Site.zip" 
				Remove-Item -path "C:\inetpub\wwwroot" -Force -Recurse -ErrorAction SilentlyContinue
				Invoke-WebRequest $using:webDeployPackage -OutFile $dest
				Add-Type -assembly "system.io.compression.filesystem"
				[io.compression.zipfile]::ExtractToDirectory($dest, "C:\inetpub\wwwroot")

				## create 443 binding from the cert store
				$certPath = 'cert:\LocalMachine\' + $using:certStoreName				
				$certObj = Get-ChildItem -Path $certPath -DNSName $using:certDomain
				if($certObj)
				{
					New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https					
					$certWThumb = $certPath + '\' + $certObj.Thumbprint 
					cd IIS:\SSLBindings
					get-item $certWThumb | new-item 0.0.0.0!443

					# Create URL Rewrite Rules
					cd c:
					Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webserver/rewrite/GlobalRules" -name "." -value @{name='HTTP to HTTPS Redirect'; patternSyntax='ECMAScript'; stopProcessing='True'}
					Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webserver/rewrite/GlobalRules/rule[@name='HTTP to HTTPS Redirect']/match" -name url -value "(.*)"
					Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webserver/rewrite/GlobalRules/rule[@name='HTTP to HTTPS Redirect']/conditions" -name "." -value @{input="{HTTPS}"; pattern='^OFF$'}
					Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/globalRules/rule[@name='HTTP to HTTPS Redirect']/action" -name "type" -value "Redirect"
					Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/globalRules/rule[@name='HTTP to HTTPS Redirect']/action" -name "url" -value "https://{HTTP_HOST}/{R:1}"
					Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/globalRules/rule[@name='HTTP to HTTPS Redirect']/action" -name "redirectType" -value "SeeOther"
				}				
			}
			DependsOn  = "[WindowsFeature]WebServerRole"
		}

		## configure IIS Rewrite rules 
		#Script ReWriteRules
		#{
		#	#Adds rewrite allowedServerVariables to applicationHost.config
		#	DependsOn = "[Package]UrlRewrite"
		#	SetScript = {
		#		$current = Get-WebConfiguration /system.webServer/rewrite/allowedServerVariables | select -ExpandProperty collection | ?{$_.ElementTagName -eq "add"} | select -ExpandProperty name
		#		$expected = @("HTTPS", "HTTP_X_FORWARDED_FOR", "HTTP_X_FORWARDED_PROTO", "REMOTE_ADDR")
		#		$missing = $expected | where {$current -notcontains $_}
		#		try
		#		{
		#			Start-WebCommitDelay 
		#			$missing | %{ Add-WebConfiguration /system.webServer/rewrite/allowedServerVariables -atIndex 0 -value @{name="$_"} -Verbose }
		#			Stop-WebCommitDelay -Commit $true 
		#		} 
		#		catch [System.Exception]
		#		{ 
		#			$_ | Out-String
		#		}
		#	}
		#	TestScript = {
		#		$current = Get-WebConfiguration /system.webServer/rewrite/allowedServerVariables | select -ExpandProperty collection | select -ExpandProperty name
		#		$expected = @("HTTPS", "HTTP_X_FORWARDED_FOR", "HTTP_X_FORWARDED_PROTO", "REMOTE_ADDR")
		#		$result = -not @($expected| where {$current -notcontains $_}| select -first 1).Count
		#		return $result
		#	}
		#	GetScript = {
		#		$allowedServerVariables = Get-WebConfiguration /system.webServer/rewrite/allowedServerVariables | select -ExpandProperty collection
		#		return $allowedServerVariables
		#	}
		#}

		# Install SSL Certificate
		#Script DeployAppCert
  #      {
  #          SetScript =  {
		#	Import-PfxCertificate -FilePath \\XXXdemoad01\source\certs\MyWebAppCert.pfx -CertStoreLocation Cert:\LocalMachine\WebHosting
		#	}
  #          TestScript = "try { (Get-Item Cert:\LocalMachine\WebHosting\C534DFBFE8DB597F22320682F7BBFBA2611DC45A -ErrorAction Stop).HasPrivateKey} catch { `$False }"
  #          GetScript = {
		#		@{Ensure = if ((Get-Item Cert:\LocalMachine\WebHosting\C534DFBFE8DB597F22320682F7BBFBA2611DC45A -ErrorAction SilentlyContinue).HasPrivateKey) 
  #            {'Present'} 
  #            else {'Absent'}}
		#	  }
  #          DependsOn = "[WindowsFeature]WebServerRole"
  #      }

		# Copy the website content 
		File WebContent 
		{ 
			Ensure          = "Present" 
			SourcePath      = "C:\WebApp"
			DestinationPath = "C:\Inetpub\wwwroot"
			Recurse         = $true 
			Type            = "Directory" 
			DependsOn       = "[Script]DeployWebPackage" 
		}		
		
  }
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
