# STAMP Template

This template bootstraps the full infrastructure for hosting OPEN edX On Azure Stamp. It includes the following:
* VMSS - frontends
* MongoDB - Mongo High-Availability Replicaset 
* Mysql - Mysql High-Availability Master-Slave(s) Replication
* Jumpbox - Utility server

We support 2 modes of bootstrapping this deployment to your environment:

1. **Azure Market Place (AMP) Deployment** - this option has a limited set of configurable options and pre-requisites. Detailed instructions for this deployment option can be found here: **[OPEN edX on Azure Ficus Deployment Documentation - AMP](http://aka.ms/openedxonazuredeploymentdocumentamp "AMP deployment Documentation")**. To bootstrap the OPEN edX on Azure STAMP, click on the "Deploy to Azure" button below: 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[![Deploy OPEN edX on Azure Stamp](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2fMicrosoft%2foxa-tools%2foxa%2fmaster.fic.eltonc.stampv2amp%2ftemplates%2fstamp%2fstamp-v2-amp.json)

2. **Powershell Deployment**  - this option exposes the full range of configuration/customization options but has a number of pre-requisites. Detailed instructions for executing this option can be found here: **[OPEN edX on Azure Ficus Deployment Documentation](http://aka.ms/openedxonazuredeploymentdocument "OPEN edX on Azure Ficus Deployment Documentation")**

  * How-To Videos for Powershell Deployment: 
    * [Session 1](https://aka.ms/plfy25)  
    * [Session 2](https://aka.ms/lrxujp)
    * [Session 3](https://aka.ms/w67l6m)