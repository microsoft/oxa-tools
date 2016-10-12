# stamp

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2Foxa-tools%2Fmaster%2Ftemplates%2Fstamp%2Fstamp.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2Foxa-tools%2Fmaster%2Ftemplates%2Fstamp%2Fstamp.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template bootstraps the full infrastructure for hosting OpenEdx On Azure Stamp. It includes the following:
* VMSS - frontends
* MongoDB - Mongo High-Availability Replicaset 
* Mysql - Mysql High-Availability Master-Slave(s) Replication
* Jumpbox - Utility server


To bootstrap this deployment to your environment, run the following:
* wget https://raw.githubusercontent.com/chenriksson/oxa-tools/master/scripts/deploy.sh -O- | bash

