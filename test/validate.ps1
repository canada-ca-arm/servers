Param(
    [Parameter(Mandatory = $false)][string]$templateLibraryName = "asg",
    [string]$templateName = "azuredeploy.json",
    [string]$Location = "canadacentral",
    [string]$subscription = "2de839a0-37f9-4163-a32a-e1bdb8d6eb7e"
)

$serversDevURL = "https://raw.githubusercontent.com/canada-ca-azure-templates/servers/dev/azuredeploy.json"

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

Select-AzureRmSubscription -Subscription $subscription

# Cleanup validation resource content in case it did not properly completed and left over components are still lingeringcd
Write-Host "Cleanup validation resource content...";
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Mode Complete -TemplateFile (Resolve-Path "$PSScriptRoot\parameters\cleanup.json") -Force -Verbose

# Start the deployment
Write-Host "Starting deployment...";

New-AzureRmDeployment -Location $Location -Name "Deploy-Infrastructure-Dependancies" -TemplateUri "https://raw.githubusercontent.com/canada-ca/accelerators_accelerateurs-azure/master/Templates/arm/masterdeploy/20190319.1/masterdeploysub.json" -TemplateParameterFile (Resolve-Path -Path "$PSScriptRoot\parameters\masterdeploysub.parameters.json") -Verbose;

$provisionningState = (Get-AzureRmDeployment -Name "Deploy-Infrastructure-Dependancies").ProvisioningState

if ($provisionningState -eq "Failed") {
    Write-Host "One of the jobs was not successfully created... exiting..."
    exit
}

# Validating server template
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "validate-$templateLibraryName-Build-$templateLibraryName" -TemplateUri $serversDevURL -TemplateParameterFile (Resolve-Path "$PSScriptRoot\parameters\validate-servers.parameters.json") -Verbose

$provisionningState = (Get-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "validate-$templateLibraryName-Build-$templateLibraryName").ProvisioningState

if ($provisionningState -eq "Failed") {
    Write-Host  "Test deployment failed..."
}

# Cleanup validation resource content
Write-Host "Cleanup validation resource content...";
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Mode Complete -TemplateFile (Resolve-Path "$PSScriptRoot\parameters\cleanup.json") -Force -Verbose