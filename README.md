# Helm Chart Publish

This Github action allows you to publish a helm repository via Github Pages. It adds an improved Bash wrapper on top of the [Helm Chart Releaser](https://github.com/helm/chart-releaser-action). The main benefit of this wrapper  is currently, that each chart is checked if it has changes in it's `Chart.yaml` file. If not, no new release will be made. The script will create for each chart a GitHub release through Chart Releaser. The index.yaml will be updated on the `gh-pages` branch.


## Setup

With the following steps you can use this action in your repository:

  1. Create a Branch called `gh-pages` on the repository. If you want  a simple landing page you can use [jekyll](https://jekyllrb.com/docs/pages/). I advise you follow [this tutorial](https://pages.github.com/) if you are new to pages.
  2. Add this action to  your Github workflows.
  3. Change configurations as needed.

## Variables

Here is a list which variables can be given/used by the script. Some values can be set over action input values. If not, there's an environment variable to change the behavior.

| Input | Description | Environment Variable | Default |
| :---- | :---------- | :------------------- | :------ |
| `config` | Define a Chart Releaser config  file. | - | `${HOME}/cr.yaml` |
| `chartConfig` | Define filename for [Chart Configurations](#chart-configuration) | - | `.chart-config` |
| `chartRoot` | Define the root  directory for your charts. If you have multiple chart directories I would advise doing multiple Github jobs. | - | `charts/` |
| `token` | Define a token which is used to create the chart releases and make changes to the gh-pages branch. | `$CR_TOKEN` | - |
| `repository` | Define where to index for the helm repository is published. This is mainly used to append new changes to an existing index via Chart Releaser. If no index is found, a new index will be created. | `$CR_REPO_URL` | `https://$(cut -d '/' -f 1 <<< $GITHUB_REPOSITORY).github.io/$(cut -d '/' -f 2 <<< $GITHUB_REPOSITORY)/` |
| - | Define the owner of the project. By default the current actor's name is used. | `$CR_OWNER` | `$(cut -d '/' -f 1 <<< $GITHUB_REPOSITORY)` |
| - | Define the project, which will be updated. By default the current running project is used.  | `$CR_GIT_REPO` | `$(cut -d '/' -f 2 <<< $GITHUB_REPOSITORY)` |
| `user` | Define the user name used for commits (pages update). | `$GIT_USER` | `$GITHUB_ACTOR` |
| `email` | Define the user email used for commits (pages update). | `$GIT_EMAIL` | `$GITHUB_ACTOR@users.noreply.github.com` |

## Chart Configuration

Certain configurations are required on chart basis. With the following variables there's the possibility to change a single charts behavior. By default you can place these variables in a file called `.chart-config` in a chart directory.

| Variable | Description | Values |
| :------- | :---------- | :----- |
| `DISABLE` | Disables the chart during the release process. | `true`/`false` |
| `SCHEMA_GENERATE` | Generates Schema with [helm-schema-gen](https://github.com/karuppiah7890/helm-schema-gen) if no values.schema.json file exists. | `true`/`false` |
| `SCHEMA_VALUES` | Define the location of the values file within the chart directory, which is used to generate the values schema. | `values.yaml` |
| `SCHEMA_FORCE` | If there is already a `values.schema.json` file present in the chart directory, no schema will be generated. This option forces to generate the schema and overwrite present schema files. | `true`/`false` |


KUBE_LINTER_DISABLE
KUBE_LINTER_CONFIG
KUBE_LINTER_ALLOW_FAIL








### Examples

Disable a chart (Won't create a new release)

**charts/sample-chart/.chart-config**

```
DISABLE=true
```

Enable enforced Schema Generation

**charts/sample-chart-2/.chart-config**

```
SCHEMA_GENERATE=true
SCHEMA_FORCE=true
```

## Usage

Using this action with it's default values is very easy. Just pass the Built-In `$GITHUB_TOKEN` environment  variable and you are good to go:

```
name: Helm Chart Release
on:
  push:
    branches:
      - master
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Fetch history
        run: git fetch --prune --unshallow

      - name: Helm Chart Publish
        uses: Kubernetli/helm-release-action@master
        with:
          token: "${{ secrets.GITHUB_TOKEN }}"
```

As reference, take a look at our [helm-charts](https://github.com/Kubernetli/helm-charts)  directory, we use this action as well.

## Contributing

We'd love to have you contribute! Please refer to our [contribution guidelines](CONTRIBUTING.md) for details.

**By making a contribution to this project, you agree to and comply with the
[Developer's Certificate of Origin](https://developercertificate.org/).**
