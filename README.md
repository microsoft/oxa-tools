# oxa-tools

Deploying and maintaining Open edX on Azure

## Deploying single machine instance (for development and test)

Execute onebox.sh on any Ubuntu 16 machine.

Common parameter argument options: pick a cell from each column. The first row is what happens when no additional parameter arguments are provided.

`--role` or `-r` or <br/> `--stack` or `-s` | `--branches` or `-b` | credential parameter arguments
--- | --- | ---
`fullstack` (default) | `edge` (default) <br/> (will use branches like oxa/dev.fic ) | randomly generated (default)
`devstack` | `release`  <br/> (will use branches like oxa/release.fic ) | `--default-password` or `-d` <br/> `anyString` (set all passwords to anyString)
n/a | `stable`  <br/> (will use branches like oxa/master.fic) | n/a
 n/a | `edx`  <br/> (will use upstream edx repositories <br/> and open-release/ficus.1 tag) | n/a
 n/a | edit onebox.sh to specify custom <br/> remote urls and branches directly | edit onebox.sh to specify custom <br/> usernames and passwords directly

For example:
`sudo onebox.sh` OR
`sudo bash onebox.sh -r devstack -b stable -d hokiePokiePass11`

What's been tested: server edition on azure, desktop edtion in virtualbox VM, docker containers with systemd. Please open an "issue" in github if you encounter any problems.

## Deploying high availability instance (for production-like environments)

documentation coming soon

## todo:
 * 100628 more documentation for all types of onebox (fullstack and devstack) deployments
 * 100632 re-enable fullstack hyperlink "button" deployment to azure
 * documentation for deploying high availability "STAMP" deployments
 * 100626 there are still a few customizations that aren't applied during onebox installation like sites, themes, etc.
