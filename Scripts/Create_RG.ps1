Connect-AzureRmAccount
#You need an SSH key pair to complete this quickstart. If you already have an SSH key pair, you can skip this step.
#ssh-keygen -t rsa -b 2048
#Variables
$ResourceGroup="NEWNEXUSRG"
$Location="EASTUS"
$storageAccountType="Standard_GRS"
#Create an Azure resource group
New-AzureRmResourceGroup -Name $ResourceGroup -Location $Location

# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
  -Name "mySubnet" `
  -AddressPrefix 192.168.1.0/24

# Create an inbound network security group rule for port 443
$nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleSSH"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 443 `
  -Access "Allow"

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleWWW"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access "Allow"

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup `
  -ResourceGroupName $ResourceGroup `
  -Location $Location `
  -Name "myNetworkSecurityGroup" `
  -SecurityRules $nsgRuleSSH,$nsgRuleWeb

Select-AzureRmSubscription -SubscriptionName 01a345dc-4adf-40ab-94ae-4d15d0058a85

New-AzureRmResourceGroupDeployment -Name NexusDeployment -ResourceGroupName NEWNEXUSRG  -TemplateUri https://raw.githubusercontent.com/amitanilsinha/NEXUS/master/Scripts/azuredeploy_linux.json
