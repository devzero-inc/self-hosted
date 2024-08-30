# DZ Self Hosted

## Setup

Clone the repository:
`git clone git@github.com:devzero-inc/self-hosted.git`

Add docker registry token to dz/docker.txt
`echo <REGISTRY_TOKEN> > dz/docker.txt`

*Registry token has to be provided by one of the DevZero employees*

## Run

Run the following script:
`./install.sh`

*Wait for script to execute*

Script will ask for license token. License token has to be provided to you by one of the DevZero employees.

## Access

After execution has completed, access the DevZero [Dashboard](http://localhost:3000/dashboard) in you browser.

## Setup the CLI

Use the following command to install the CLI:
`curl https://get.devzero.io | sh`

## Authenticate

After you build your first recipe, and launch your first workspace, inside of the connect button you will find JWT token that you have to copy.

`sudo dz cli set-context --control-plane-token <INPUT_JWT_HERE> --control-plane-url http://localhost:8831 --network-login-server-url http://localhost:8181`

## Connect to your workspace

List your workspaces:
`dz ws list`

After you list your workspace, use the name of the workspace to connect to it (or you can tab into it :D)
`dz ws connect <WORKSPACE_NAME>`
