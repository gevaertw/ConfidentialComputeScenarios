//Parameters comming from parameter file:------------------------------------------------------------------------------------------------------------

param dateNow string = utcNow('d')
param timeNow string = utcNow('t')

@description('The Azure subscription into which the resources should be deployed.')
param subscriptionID string = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

@description('The Azure region into which the resources should be deployed.')
param regionName string = 'North Europe'

@description('Username for the Virtual Machine.')
@secure()
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string 

@description('The key Vault URL where encrytion keys are stored.  Do not add a trailing / to the url.  The script will assume that the keyname is in the format of vmname-diskencryptionkey')
@secure()
param diskEncryptionKeyVaultURL string

@description('Managed identity for the Virtual Machine disk encryption sets.  Full url')
@secure()
param diskEncryptionKeyvaultManagedIdentityID string

//Top level variables:-------------------------------------------------------------------------------------------------------------------------------
@description('The Azure taglist.')
var tagList =  {
  deployDate: dateNow
  deployTime: timeNow
  BicepDeployed: 'Yes'
  CostCenter: 'ConfidentialVMDemo'
  environment: 'Experimental'
}

@description('The Azure region name without spaces into which the resources should be deployed.  Use this form azure compliant that need the region in the name')
var regionNameClean = replace(regionName,' ','')

@description('The confidentialVM vNet name')
var confidentialVMVnetName = 'vnet-confidentialVM-${regionNameClean}'
@description('The confidentialVM vNet address space')
var confidentialVMVnetAddressSpace = '10.0.0.0/20'

@description('The confidentialVM name')
var confidentialVMName = 'vm-appsrv01'



// Deploy RG's
targetScope = 'subscription'
resource rg_ACCscenarios_confidentialVM_Resource 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'rg-ACCscenarios-confidentialVM'
  location: regionName
  tags: tagList
}

// deploy the network
module vNet_ACCscenarios_confidentialVM_Module 'createvNetSubnets.bicep' = {
  name: 'vNet-ACCscenarios-confidentialVM'
  scope: resourceGroup('rg-ACCscenarios-confidentialVM')
  dependsOn: [
    rg_ACCscenarios_confidentialVM_Resource
  ]
  params:{
    regionName: regionName
    tagList: tagList
    vNetName: confidentialVMVnetName
    vNetAddressSpace: confidentialVMVnetAddressSpace
  }
}

// Deploy the VM
module ACCscenarios_confidentialVM_Resource_mod 'ACCscenarios_confidentialVM.bicep' ={
  name: 'ACCscenarios_confidentialVM_Resource_mod'
  scope: resourceGroup('rg-ACCscenarios-confidentialVM')
  dependsOn: [
    vNet_ACCscenarios_confidentialVM_Module
  ]
  params:{
    adminPassword: adminPassword
    adminUsername: adminUsername
    regionName: regionName
    tagList: tagList
    vmName: confidentialVMName
    vmSize: 'Standard_DC2as_v5'
    osDiskType: 'StandardSSD_LRS'
    dataDisk01Type: 'Premium_LRS'
    subnetName: '${confidentialVMVnetName}/${confidentialVMVnetName}-snet-00'
    diskEncryptionKeyVaultURL: diskEncryptionKeyVaultURL
    diskEncryptionKeyvaultManagedIdentityID : diskEncryptionKeyvaultManagedIdentityID
  }  
}

