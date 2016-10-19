# oxa-tools

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMicrosoft%2Foxa-tools%2Fmaster%2Ftemplates%2Fscalable.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FMicrosoft%2Foxa-tools%2Fmaster%2Ftemplates%2Fscalable.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

To deploy from an edX app VM:
* wget https://raw.githubusercontent.com/Microsoft/oxa-tools/master/scripts/deploy.sh -O- | bash

Future deployment work:
* Deploy using ARM CustomScript extension. Work in progress, see /templates.
* Consider deploying ARM via Azure powershell, possibly from VS ARM project
* Extensions for specific tasks:
  * DB migration
  * Running subset of ansible tags (config, theming, etc)
