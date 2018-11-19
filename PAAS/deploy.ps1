$RG = "NexusMain"
$location = "East US"
New-AzureRmResourceGroup -Name $RG -Location $location
New-AzureRmResourceGroupDeployment -Name jenkinsaspaas -ResourceGroupName $RG `
 -TemplateUri "https://raw.githubusercontent.com/amitanilsinha/NEXUS/master/PAAS/nexusinfra.json" `
-TemplateParameterUri "https://raw.githubusercontent.com/amitanilsinha/NEXUS/master/PAAS/Nexusinfraparameter.json"

$ipname = (Get-AzureRmResource  -ResourceGroupName $RG  -ResourceType Microsoft.Network/publicIPAddresses).Name[1]
$IP = (Get-AzureRmPublicIpAddress -Name $ipname -ResourceGroupName $RG).IpAddress
Write-Host "Login from browser with $IP and port 8080" -ForegroundColor Green 
Write-Host "Login Username is admin and Password is admin123" -ForegroundColor Green
               
