	Configuration Hardening
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

		Script TurnOffFirewall
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

		Registry DisableIPv6 {
		  Key = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
		  ValueName = "DisabledComponents"
		  Ensure = "Present"
		  ValueData = 255
		  ValueType = "DWord"
		  Force = $true
		}

		Script Disable6to4 {
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
		  DependsOn = "[Registry]DisableIPv6"
		}
	  }
	}

