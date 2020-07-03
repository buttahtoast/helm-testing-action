# Helm Chart Publish

This Github action allows you to publish a helm repository via Github Pages. It adds an improved Bash wrapper on top of the [Helm Chart Releaser](https://github.com/helm/chart-releaser-action). The main benefit of this wrapper  is currently, that each chart is checked if it has changes in it's `Chart.yaml` file. If not, no new release will be made. The script

I am also looking into autmatic changelog creation for each chart


## Setup

With the following steps you can use this action in your repository:

  2. Create a Branch called `gh-pages` on the repository. If you want  a simple landing page you can use (jekyll)[https://jekyllrb.com/docs/pages/]. I advise you follow [this tutorial](https://pages.github.com/) if you are  new to pages.




## Variables

Here is a list which variables can be given/used by the script. Some values can be set over action input values. If not, there's an environment variable to change the behavior.

| Input | Description | Environment Variable | Default |
|:---|:---|:---|:---|
| `config` | Define a Chart Releaser config  file. | - | `${HOME}/cr.yaml` |
| `chartRoot` | Define the root  directory for your charts. If you have multiple chart directories I would advise doing multiple Github jobs. | - | `charts/` |
| `token` | Define a token which is used to create the chart releases and make changes to the gh-pages branch. | `$CR_TOKEN` | `` |
| `repository` | Define where to index for the helm repository is published. This is mainly used to append new changes to an existing index via Chart Releaser. If no index is found, a new index will be created. | `$CR_REPO_URL` | `https://$(cut -d '/' -f 1 <<< $GITHUB_REPOSITORY).github.io/$(cut -d '/' -f 2 <<< $GITHUB_REPOSITORY)/` |
| - | Define the owner of the project. By default the current actor's name is used. | `$CR_OWNER` | `$(cut -d '/' -f 1 <<< $GITHUB_REPOSITORY)` |
| - | Define the project, which will be updated. By default the current running project is used.  | `$CR_GIT_REPO` | `$(cut -d '/' -f 2 <<< $GITHUB_REPOSITORY)` |
| `user` | Define the user name used for commits (pages update). | `$GIT_USER` | `$GITHUB_ACTOR` |
| `email` | Define the user email used for commits (pages update). | `$GIT_EMAIL` | `$GITHUB_ACTOR@users.noreply.github.com` |




## Usage



## Contributing

We'd love to have you contribute! Please refer to our [contribution guidelines](CONTRIBUTING.md) for details.

**By making a contribution to this project, you agree to and comply with the
[Developer's Certificate of Origin](https://developercertificate.org/).**
