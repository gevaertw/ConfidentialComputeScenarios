@description('The Azure region into which the resources should be deployed.')
param regionName string
@description('The base tags the resources should be deployed with.')
param tagList object
@description('The vNet Name.')
param vNetName string
@description('The vNet address space.')
param vNetAddressSpace string
@description('A list of subnets to be created in the vnet. Not yet implemented')
param subnetList  array = ['Frontend','Application','Data']


//Networking
var subnet00AdressPrefix_tmpSplitArray = split(vNetAddressSpace,'.')

var ipa = int (subnet00AdressPrefix_tmpSplitArray[0])
var ipb = int (subnet00AdressPrefix_tmpSplitArray[1])
var ipc = int (subnet00AdressPrefix_tmpSplitArray[2])

var subnet00Name = '${vNetName}-snet-00'
var subnet00AdressPrefix = '${ipa}.${ipb}.${ipc+0}.0/24' 

var subnet01Name = '${vNetName}-snet-01'
var subnet01AdressPrefix = '${ipa}.${ipb}.${ipc+1}.0/24'

var subnet02Name = '${vNetName}-snet-02'
var subnet02AdressPrefix = '${ipa}.${ipb}.${ipc+2}.0/24'

var subnet03Name = '${vNetName}-snet-03'
var subnet03AdressPrefix = '${ipa}.${ipb}.${ipc+3}.0/24'

/* @description('The hub vNet Fully Qualified Resource Name in the primary region')
var hubvNetFQRI00 = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${hubResourceGroup}/providers/Microsoft.Network/virtualNetworks/${hubvNetName}'

@description('The hub vNet Fully Qualified Resource Name in the primary region')
var thisVnetFQRI00 = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vNetName}' */

//all landing zone deploys-------------------------------------------------------------------------
//Network deployment-------------------------------------------------------------------------------
//Vnets--------------------------------------------------------------------------------------------
resource windowsAppLandingZoneVnet01 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vNetName
  location: regionName
  tags: tagList
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressSpace
      ]
    }
    subnets: [
      {
        name: subnet00Name
        properties: {
          addressPrefix: subnet00AdressPrefix
          
        }
      }
      {
        name: subnet01Name
        properties: {
          addressPrefix: subnet01AdressPrefix
          
        }
      }
      {
        name: subnet02Name
        properties: {
          addressPrefix: subnet02AdressPrefix
          
        }
      }
      {
        name: subnet03Name
        properties: {
          addressPrefix: subnet03AdressPrefix
          
        }
      }
    ]
  }
}
