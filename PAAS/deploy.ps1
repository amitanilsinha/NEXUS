$RG = "testinart"
$location = "East US"
$customscriptname = "mycustomscript"
New-AzureRmResourceGroup -Name $RG -Location $location
New-AzureRmResourceGroupDeployment -Name artifactory -ResourceGroupName $RG `
 -TemplateUri "https://raw.githubusercontent.com/sangaml/artifactory_DSC/master/infra.json" `
-TemplateParameterUri "https://raw.githubusercontent.com/sangaml/artifactory_DSC/master/infra.parameters.json"
 $vm = (Get-AzureRmResource -ResourceGroupName $RG -ResourceType Microsoft.Compute/virtualMachines).Name[1]
 $ipname = (Get-AzureRmResource  -ResourceGroupName $RG  -ResourceType Microsoft.Network/publicIPAddresses).Name[1]
 $IP = (Get-AzureRmPublicIpAddress -Name $ipname -ResourceGroupName $RG).IpAddress
 Write-Host "Installing Java ..." -ForegroundColor Green
 Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG `
               -VMName $vm -Name $customscriptname `
               -FileUri "https://raw.githubusercontent.com/sangaml/jenkinsaspass/master/installjava.ps1" `
               -Run "installjava.ps1" `
               -Location $location 
               start-sleep 120
Remove-AzurermVMCustomScriptExtension -ResourceGroupName $RG -VMName $vm -Name $customscriptname  -Force

Write-Host "Installing Artifactory ..." -ForegroundColor Green
               Set-AzureRmVMCustomScriptExtension -ResourceGroupName $RG `
               -VMName $vm -Name $customscriptname `
               -FileUri "https://raw.githubusercontent.com/sangaml/artifactory_DSC/master/nartifactory.ps1" `
               -Run "nartifactory.ps1" `
               -Location $location 
               Write-Host "Login from browser with $IP and port 8080" -ForegroundColor Green 
               Write-Host "Login Username is admin and Password is password" -ForegroundColor Green 
               Remove-AzurermVMCustomScriptExtension -ResourceGroupName $RG -VMName $vm -Name $customscriptname -Force
               
