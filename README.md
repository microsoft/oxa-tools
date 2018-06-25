# oxa-tools

Deploying and maintaining Open edX on Azure

## Deploying single machine instance (for development and test)

Execute `onebox.sh` on any Ubuntu 16 machine.

Common parameter argument options: pick a cell from each column. The first row is what happens when no additional parameter arguments are provided.

`--role` or `-r` or <br/> `--stack` or `-s` | `--branches` or `-b` | credential parameter arguments | `--msft-oauth`
--- | --- | --- | ---
`fullstack` (default) | `edge` (default) <br/> (oxa/dev.fic branches) | randomly generated (default) | off (default)
`devstack` | `ginkgo` <br/> (edx repositories and <br/> open-release/ginkgo.1 tag) | `--default-password` or `-d` <br/> `anyString` <br/> (set all passwords to anyString) | `prod` <br/> (uses login.live)
 &nbsp; | `release` <br/> (oxa/release.fic branches)  | &nbsp; | &nbsp; 
 &nbsp; | `stable` <br/> (oxa/master.fic branches) | &nbsp; | &nbsp; 
 &nbsp; | `ficus` <br/> (edx repositories and <br/> open-release/ficus.1 tag) | &nbsp; | &nbsp; 
 &nbsp; | edit onebox.sh to specify custom <br/> remote urls and branches directly | edit onebox.sh to specify custom <br/> usernames and passwords directly | &nbsp; 

For example:
`sudo onebox.sh` OR
`sudo bash onebox.sh -r devstack -b stable -d hokiePokiePass11 --msft-oauth prod`

What's been tested: server edition on azure, desktop edition in virtualbox VM, docker containers with systemd. Please open an "issue" in Github if you encounter any problems.

## Deploying high availability instance (for production-like environments)

(pdf) https://assets.microsoft.com/en-us/openedx-on-azure-ficus-stamp-deployment.pdf

## todo:
 * 100628 more documentation for onebox (fullstack and devstack) deployments like
   *  more details on the various way of provisioning the OS
   *  hyperlinks to edx documentation for using fullstack and devstack deployments
