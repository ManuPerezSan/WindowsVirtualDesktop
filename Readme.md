# WVD-Report
Connect to your Windows Virtual Desktop and obtain data about your environment (host pools, application groups, published apps and sessions)

## Parameter AzureTenantId
    Azure tenant Id (Azure Portal > Azure Active Directory > Overview)

## Parameter SubscriptionId
    Azure subscription Id (Azure Portal > Subscription > Overview)

## Parameter ClientId
  App Id (Azure Portal > Azure Active Directory > App registration)
  How to create it: https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal

## Parameter ClientSecret
  The secret of the client Id

## Outfile
    The name of the output file file

## Requirements
  An Azure subscription with Azure Active Directory
  An App Id (App registration) with Reader role in the subscription
  Powershell Az or AzureRM not required

## Output
    Save html report with name WVDTool.html in the same folder

![image](https://user-images.githubusercontent.com/23212171/101169441-367d0500-363d-11eb-807d-394380cc2680.png)

![image](https://user-images.githubusercontent.com/23212171/100673558-ef082780-3363-11eb-9e93-4fe6cc79cc01.png)
