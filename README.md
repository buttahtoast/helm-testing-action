# Helm Chart Publish

This Github action allows you to publish a helm repository via Github Pages. It integrates [Kube-Linter](https://github.com/stackrox/kube-linter), [Helm Values Generator](https://github.com/karuppiah7890/helm-schema-gen) and [Helm Unit Testing](https://github.com/quintush/helm-unittest) as tools, to improve the quality of your published helm charts. It adds an improved Bash wrapper on top of the [Helm Chart Releaser](https://github.com/helm/chart-releaser-action). The main benefit of this wrapper  is currently, that each chart is checked if it has changes in it's `Chart.yaml` file. If not, no new release will be made. The script will create for each chart a GitHub release through Chart Releaser. The index.yaml will be updated on the `gh-pages` branch.


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
| `dryrun` | Run Publishing Action without publishing charts. | `-` | `false` |
| `force` | Force publishing even if charts had errors (publish only charts without error) | `-` | `false` |
| `schemaDisable` | Disable Global [Helm Values Generator](https://github.com/karuppiah7890/helm-schema-gen) Usage. No chart can use this feature. | `-` | `false` |
| `schemaAllowFailure` | Global Schema Generator Configuration. If a Schema Generator fails, the chart will not be marked as error and therefor might be released. This parameters allows this behavior for all charts. | `-` | `false` |
| `kubeLinterDisable` | Disable Global [Kube-Linter](https://github.com/stackrox/kube-linter) Usage. No chart can use this feature. | `-` | `false` |
| `kubeLinterDefaultConfig` | Global Kube-Linter Configuration. With this parameter you can define the location for your global Kube-Linter configuration. Meaning this configuration will be used for each chart (if possible). The path is relative to the root folder of the repository. | `-` | `./.kube-linter.yaml` |
| `kubeLinterAllowFailure` | Global Kube-Linter Configuration. If a Kube-linting fails, the chart will not be marked as error and therefor might be released. This parameters allows this behavior for all charts. | `-` | `false` |
| `unitTestDisable` | Disable Global [Helm Unit Testing](https://github.com/quintush/helm-unittest) Usage. No chart can use this feature. | `-` | `false` |
| `unitTestAllowFailure` | Global Helm Unit Test Configuration. If a Helm Unit Test fails, the chart will not be marked as error and therefor might be released. This parameters allows this behavior for all charts. | `-` | `false` |

## Chart Configuration

Certain configurations are required on chart basis. With the following variables there's the possibility to change a single charts behavior. By default you can place these variables in a file called `.chart-config` in a chart directory.

| Variable | Description | Values |
| :------- | :---------- | :----- |
| `DISABLE` | Disables the chart during the release process. | `true`/`false` |
| `SKIP_PUBLISH` | Executes all checks but does not create a package/publish the chart | `true`/`false` |
| `SCHEMA_ENABLE` | Generates Schema with [helm-schema-gen](https://github.com/karuppiah7890/helm-schema-gen) if no values.schema.json file exists. | `true`/`false` |
| `SCHEMA_VALUES` | Define the location of the values file within the chart directory, which is used to generate the values schema. | `values.yaml` |
| `SCHEMA_FORCE` | If there is already a `values.schema.json` file present in the chart directory, no schema will be generated. This option forces to generate the schema and overwrite present schema files . | `true`/`false` |
| `SCHEMA_ALLOW_FAIL` | Allows the failure of the Schema Generator action for this specific chart (if not set globally). | `true`/`false` |
| `KUBE_LINTER_DISABLE` | Disable Kube-Linter action for this specific chart (if not disabled globally) | `true`/`false` |
| `KUBE_LINTER_CONFIG` | Define a path to a custom Kube-Linter  configuration Kube-Linter for this chart. The path is relative to the specifics chart subfolder. This configuration will be merged with the global Kube-Linter configuration, if present. See the [Examples](#examples) | `.kube-linter.yaml` |
| `KUBE_LINTER_ALLOW_FAIL` | Allows the failure of the Kube-Linter action for this specific chart (if not set globally). | `true`/`false` |
| `UNIT_TEST_DISABLE` | Disable Helm Unit-Test action for this specific chart (if not disabled globally) | `true`/`false` |
| `UNIT_TEST_ARGS` | Additional arguments for `helm unittest` | `-` |
| `UNIT_TEST_ALLOW_FAIL` | Allows the failure of the Helm Unit-Test action for this specific chart (if not set globally). | `true`/`false` |

## Examples

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

## Using Kube-Linter

Before you start, check out how to create Kube-Linter configurations [here](https://github.com/stackrox/kube-linter/blob/main/docs/configuring-kubelinter.md). The Kube-Linter configurations are merged with [spruce](https://github.com/geofffranks/spruce). This means you can combine per chart Kube-Linter configurations with the global configuration. Let me show you:

**./.kube-linter.yaml** (Global Configuration)

```
---
checks:
  addAllBuiltIn: true
  execlude:
    - "default-service-account"
    - "no-anti-affinity"
    - "required-annotation-email"
```

**./charts/mychart/.kube-linter.yaml** (Per Chart Configuration)

```
---
checks:
  execlude:
    - (( prepend ))
    - "required-label-owner"
    - "unset-cpu-requirements"
    - "unset-memory-requirements"
```

Results in:

```
checks:
  addAllBuiltIn: true
  execlude:
  - required-label-owner
  - unset-cpu-requirements
  - unset-memory-requirements
  - default-service-account
  - no-anti-affinity
  - required-annotation-email
```

All [spruce operators](https://github.com/geofffranks/spruce/blob/master/doc/operators.md) are supported.

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
