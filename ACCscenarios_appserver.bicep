@description('The Azure region into which the resources should be deployed.')
param regionName string

@description('The tags on the resources.')
param tagList object

@description('The VM Name.')
param vmName string

@description('Username for the Virtual Machine.')
@secure()
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('The key Vault URL where encrytion keys are stored.  The script will assume that the keyname is in the format of vmname-diskencryptionkey')
@secure()
param diskEncryptionKeyVaultURL string

resource diskEncryptionKey 'Microsoft.KeyVault/vaults/keys@2023-02-01' existing = {
  name: '${vmName}-diskencryptionkey'
}

var diskEncryptionKeyURL_Latest = dataUriToString(listKeys(diskEncryptionKeyVaultURL, '${vmName}-diskencryptionkey').value[0].kid)

@description('Managed identity for the Virtual Machine disk encryption sets.')
@secure()
param diskEncryptionKeyvaultManagedIdentityName string

resource diskEncryptionKeyvaultManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: diskEncryptionKeyvaultManagedIdentityName
  //location : regionName
}

var diskEncryptionKeyvaultManagedIdentityID = diskEncryptionKeyvaultManagedIdentity.id

@description('The Windows version for the VM. This will pick a fully patched Gen2 image of this given Windows version.')
@allowed([
  '2019-datacenter-gensecond'
  '2019-datacenter-core-gensecond'
  '2019-datacenter-core-smalldisk-gensecond'
  '2019-datacenter-core-with-containers-gensecond'
  '2019-datacenter-core-with-containers-smalldisk-g2'
  '2019-datacenter-smalldisk-gensecond'
  '2019-datacenter-with-containers-gensecond'
  '2019-datacenter-with-containers-smalldisk-g2'
  '2016-datacenter-gensecond'
  '2019-datacenter-smalldisk-g2'
])
param windowsOSVersion string = '2019-datacenter-smalldisk-g2'

@description('Size of the confidential virtual machine.')
@allowed([
  'Standard_DC2as_v5'
  'Standard_DC4as_v5'
  'Standard_DC8as_v5'
])
param vmSize string = 'Standard_DC2as_v5'

@description('OS Disk Type')
@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
param osDiskType string = 'Standard_LRS'

@description('Data Disk 01 Type')
@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
param dataDisk01Type string = 'Standard_LRS'

@description('The subnet.  It should be in the format vnet/subnet')
param subnetName string

resource VMsubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  name: subnetName
}

resource vmNIC 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'nic-${vmName}nic01'
  location: regionName
  dependsOn: [
    VMsubnet
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig01'
        properties: {
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: VMsubnet.id
            name: VMsubnet.name
          }
        }
      }
    ]
  }
}

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2022-07-02' = {
  name: 'de-${vmName}'
  location: regionName
  tags: tagList
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/3e5176f0-de10-4063-b568-03438b52f00e/resourcegroups/permanent/providers/Microsoft.ManagedIdentity/userAssignedIdentities/diskEncryptionKeyvaultManagedIdentity-01': {}
    }
  }
  properties: {
    activeKey: {
      keyUrl: 'https://kv-azureplayground02.vault.azure.net/keys/vm-appsrv01-diskencryptionkey/2d4dd556445f41c39de4a58005fb5d15'
    }
    encryptionType: 'EncryptionAtRestWithCustomerKey'
    federatedClientId: 'none' //multi tennant keyvault stuf here
    //rotationToLatestKeyVersionEnabled: true
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: regionName
  tags: tagList
  dependsOn: [
    diskEncryptionSet, vmNIC
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
          securityProfile: {
            securityEncryptionType: 'VMGuestStateOnly'
          }
        }
      }
      diskControllerType: 'SCSI'
      dataDisks: [
        {
          lun: 0
          name: '${vmName}_DataDisk_0'
          createOption: 'Empty'
          caching: 'ReadOnly'
          writeAcceleratorEnabled: false
          managedDisk: {
            storageAccountType: 'Premium_LRS'
            
            diskEncryptionSet: {
              id: diskEncryptionSet.id
            }
            //id: resourceId('Microsoft.Compute/disks', '${vmName}_DataDisk_0')
          }
          deleteOption: 'Delete'
          diskSizeGB: 1024
          toBeDetached: false
        }
      ]

    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNIC.id
        }
      ]
    }
    securityProfile: {
      // encryptionAtHost: false // 
      securityType: 'ConfidentialVM'
        uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
}
