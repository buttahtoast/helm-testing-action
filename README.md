# Helm Chart Testing

A simple action which provides additional scripts to improve the helm chart release process for Github. Adds the following Addons:

  * [Helm Unit Testing](https://github.com/quintush/helm-unittest)
  * [Kube-Linter](https://github.com/stackrox/kube-linter)
  * [Helm Docs](https://github.com/norwoodj/helm-docs)

## Setup/Usage

This action is build to be used together with the [chart testing action](https://github.com/helm/chart-testing-action):

```
name: Linting and Testing
on: pull_request
jobs: 
  chart-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Set up Helm
        uses: azure/setup-helm@v1

      - uses: actions/setup-python@v2
        with:
          python-version: 3.7

      - name: Setup Chart Linting
        id: lint
        uses: helm/chart-testing-action@v2.0.1

      - name: List changed charts
        id: list-changed
        run: |
          ## If executed with debug this won't work anymore.
          changed=$(ct --config ./ct.yaml list-changed)
          charts=$(echo "$changed" | tr '\n' ' ' | xargs)
          if [[ -n "$changed" ]]; then
            echo "::set-output name=changed::true"
            echo "::set-output name=changed_charts::$charts"
          fi
      - name: Run chart-testing (lint)
        run: ct lint --config ./ct.yaml 

      ## Runs Helm-Docs Script
      - name: Run docs-testing (helm-docs)
        uses: buttahtoast/helm-release-action@master
        with:
          charts: "${{ steps.list-changed.outputs.changed_charts }}"
        if: steps.list-changed.outputs.changed == 'true'  
 
      ## Runs Kube-Linter Script
      - name: Run kube-linter 
        uses: buttahtoast/helm-release-action@master
        with:
          exec: "linter"
          charts: "${{ steps.list-changed.outputs.changed_charts }}"
        if: steps.list-changed.outputs.changed == 'true'  

      ## Runs Unit-Tests Script
      - name: Run Unit-Tests
        uses: buttahtoast/helm-release-action@master
        with:
          exec: "unit-tests"
          charts: "${{ steps.list-changed.outputs.changed_charts }}"
        if: steps.list-changed.outputs.changed == 'true'
```

Per default, the [docs.sh](./scripts/docs.sh) script is executed. You can changed which script should be executed over an action parameter.


## Variables

Here is a list which variables can be given/used by the script. Some values can be set over action input values. If not, there's an environment variable to change the behavior.

| Input | Description | Environment Variable | Default |
| :---- | :---------- | :------------------- | :------ |
| `chartConfig` | Define filename for [Chart Configurations](#chart-configuration) | - | `.chart-config` |
| `exec` | Define which script to execute with the action | - | `docs` |
| `charts` | Iterateable list for script validation (See example for ct output) | - | - |

## Chart Configuration

Certain configurations are required on chart basis. With the following variables there's the possibility to change a single charts behavior. By default you can place these variables in a file called `.chart-config` in a chart directory.

| Variable | Description | Values |
| :------- | :---------- | :----- |
| `HELM_DOCS_DISABLE` | Disable Helm-Docs execution for this chart| `true/false` |
| `HELM_DOCS_ALLOW_FAIL` | Allow Helm-Docs execution to fail for this chart (Action won't fail) | `true/false` |
| `KUBE_LINTER_DISABLE` | Disable Kube-Linter execution for this chart | `true`/`false` |
| `KUBE_LINTER_ALLOW_FAIL` | Allow Kube-Linter execution to fail for this chart (Action won't fail) | `true`/`false` |
| `UNIT_TEST_DISABLE` | Disable Helm Unit-Test execution for this chart | `true`/`false` |
| `UNIT_TEST_ARGS` | Additional arguments for `helm unittest` | `-` |
| `UNIT_TEST_ALLOW_FAIL` | Allow Unit-Tests execution to fail for this chart (Action won't fail)  | `true`/`false` |

## Examples

## Using Kube-Linter

Before you start, check out how to create Kube-Linter configurations [here](https://github.com/stackrox/kube-linter/blob/main/docs/configuring-kubelinter.md). The Kube-Linter configurations are merged with [spruce](https://github.com/geofffranks/spruce). This means you can combine per chart Kube-Linter configurations with the global configuration. Let me show you:

**./.kube-linter.yaml** (Global Configuration)

```
---
checks:
  addAllBuiltIn: true
  exclude:
    - "default-service-account"
    - "no-anti-affinity"
    - "required-annotation-email"
```

**./charts/mychart/.kube-linter.yaml** (Per Chart Configuration)

```
---
checks:
  exclude:
    - (( prepend ))
    - "required-label-owner"
    - "unset-cpu-requirements"
    - "unset-memory-requirements"
```

Results in:

```
checks:
  addAllBuiltIn: true
  exclude:
  - required-label-owner
  - unset-cpu-requirements
  - unset-memory-requirements
  - default-service-account
  - no-anti-affinity
  - required-annotation-email
```

All [spruce operators](https://github.com/geofffranks/spruce/blob/master/doc/operators.md) are supported.

## Contributing

We'd love to have you contribute! Please refer to our [contribution guidelines](CONTRIBUTING.md) for details.

**By making a contribution to this project, you agree to and comply with the
[Developer's Certificate of Origin](https://developercertificate.org/).**
