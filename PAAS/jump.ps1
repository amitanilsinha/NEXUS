	Configuration Hardening
	{
	  
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

