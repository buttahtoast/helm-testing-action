# helm-release-actio

This action allows you to publish a helm repository via Github Pages. It adds an improved Bash wrapper on top of the [Helm Chart Releaser](https://github.com/helm/chart-releaser-action). The main benefit of this wrapper  is currently, that each chart is checked if it has changes in it's `Chart.yaml` file. If not, no new release will be made.

I am also looking into autmatic changelog creation for each chart




## Variables

Here is a list which variables can be given/used by the script. Some values can be set over action input values. If not, there's an environment variable to change the behavior.

| Input | Description | Environment Variable | Default |
|:---|:---|:---|:---|
| `` |  | `` | `` |





## Usage
