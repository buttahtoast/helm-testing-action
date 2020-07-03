## Function: latestTag()
## Returns latest git tag, if any exists
##
latestTag() {
    if ! git describe --tags --abbrev=0 2> /dev/null; then git rev-list --max-parents=0 --first-parent HEAD; fi
}

## Function: createDirs()
## Creates required directories
##
createDirs() {
  rm -rf ${CR_RELEASE_LOCATION} && mkdir -p ${CR_RELEASE_LOCATION} ## Recreates Package Directory
  rm -rf .cr-index && mkdir -p .cr-index ## Recreates Index File
}

## Environment Variables
## CR Configuration Variables (Required)

## Define a personal token which
## can create new releases and commits
## to the repository. The default configuration
## environment variable 'CR_TOKEN' is prefered over
## the input setting.
##
export CR_TOKEN="${CR_TOKEN:-$INPUT_TOKEN}";

## Chart Releaser default repository URL.
## This URL is used to fetch the current
## repository index and expand it with
## new additions. The variable can't be empty.
##
export CR_REPO_URL="${INPUT_REPOSITORY:-https://$(cut -d '/' -f 1 <<< $GITHUB_REPOSITORY).github.io/$(cut -d '/' -f 2 <<< $GITHUB_REPOSITORY)/}";
export CR_REPO_URL="${CR_REPO_URL:?Missing required Variable}";

## Repository name under which the
## releases are created. The default configuration
## environment variable 'CR_GIT_REPO' is prefered over
## the input setting. If none of both is set, the script
## will exit.
##
export CR_OWNER="${CR_OWNER:-$(cut -d '/' -f 1 <<< $GITHUB_REPOSITORY)}";
export CR_GIT_REPO="${CR_GIT_REPO:-$(cut -d '/' -f 2 <<< $GITHUB_REPOSITORY)}";

## Configuration Option for chart directories
## defaults to "charts/" if the input variable
## is unset.
##
CHART_ROOT="${INPUT_CHARTROOT:-charts/}"

## Configuration Option for Chart Releaser config
## file. It's checked if the configuration file
## exists, only then it's added as argument
##
CR_CONFIG_LOCATION="${INPUT_CONFIG:-$HOME/.cr.yaml}"
[ -f "${CR_CONFIG_LOCATION}" ] && CR_ARGS="--config \"${CR_CONFIG_LOCATION}\"";

## Configuration Option for the name for the user used for
## git actions. The variable can't be empty.
##
GIT_USER="${INPUT_USER:-$GITHUB_ACTOR}"
GIT_USER="${GIT_USER:?Missing required Variable}";

## Configuration Option for the email for the user used for
## git actions. The variable can't be empty.
##
GIT_EMAIL="${INPUT_EMAIL:-$GITHUB_ACTOR@users.noreply.github.com}"
GIT_EMAIL="${GIT_EMAIL:?Missing required Variable}";


## Not so relevant variables for
## the GitHub action
##
CR_RELEASE_LOCATION=".cr-release-packages"

## Git Tag Fetching
## For a comparison we just need the latest tag.
##
git fetch --tags
HEAD_REV=$(git rev-parse --verify HEAD);
LATEST_TAG_REV=$(git rev-parse --verify "$(latestTag)");
if [[ "$LATEST_TAG_REV" == "$HEAD_REV" ]]; then echo -e "\n\e[33mNothing to do!\e[0m\n"; exit 0; fi

## Instead make two seperate jobs in your action
##
## Evaluate Chart directories
## Checks if the variable is split with ,
## if so, the variable is parsed as array otherwise
## as single directory
##
#if [[ ${CHART_ROOT} == *","* ]]; then
#  IFS=', ' read -r -a ROOT_DIRS <<< "${CHART_ROOT}"
#else
#  ROOT_DIRS=(${CHART_ROOT})
#fi

## Initialize for each directory a matching regex
## which finds changes in the diff statement
##
CHART_INDICATOR="$( echo ${CHART_ROOT%/} | tr -d '[:space:]' )/*/Chart.yaml"
CHANGED_CHARTS="${CHANGED_CHARTS} $(git diff --find-renames --name-only $LATEST_TAG_REV -- $CHART_INDICATOR | cut -d '/' -f 1-2 | uniq)"


## All changed charts are parsed as array
## Xargs is used to trim spaces left and right
##
readarray -t PUBLISH_CHARTS <<< "$(echo ${CHANGED_CHARTS} | xargs )"

## Checks if there were any changes made
## Because the variable structing is not super clean
## I ended up with these two checks. Might be
## improved in the future
##
if ! [[ -z $(echo "${CHANGED_CHARTS}" | xargs) ]] && [[ ${#PUBLISH_CHARTS[@]} -gt 0 ]]; then

  ## Check if charts exist as directory, this
  ## serves as simple handler when a chart is removed
  ## (if that's ever gonna happen).
  ##
  EXISTING_CHARTS=()
  for PRE_CHART in "${PUBLISH_CHARTS[@]}"; do
      TRIM_CHART="$(echo $PRE_CHART | xargs)"
      [ -d "$TRIM_CHART" ] && EXISTING_CHARTS+=($TRIM_CHART)
  done

  ## Evaluates if gh-pages branch already exists
  ## Branch won't be initialized and therefor throws
  ## an error on runtime.
  ##
  if ! [ `git branch --list 'gh-pages'` ]; then
      echo -e "\n\e[91mMissing gh-pages branch, please initialize the branch.\e[0m\n"; exit 1;
  fi

  ## Just to be sure, checking that the array
  ## is not empty
  ##
  if [[ ${#EXISTING_CHARTS[@]} -gt 0 ]]; then

      ## Create required directories
      ##
      createDirs

      ## Starting iteration for each chart to be packaged
      ## with the helm built-in function.
      ##
      echo -e "\n\e[33m- Crafting Packages\e[0m"
      for CHART in "${EXISTING_CHARTS[@]}"; do
          echo -e "\n\e[32m-- Package: $chart\e[0m"
          helm package $CHART --dependency-update --destination ${CR_RELEASE_LOCATION}
      done

      ## For each package made by helm cr will
      ## create a helm release on the GitHub Repository
      ##
      echo -e "\n\e[33m- Creating Releases\e[0m\n"
      if ! cr upload $CR_ARGS; then echo -e "\n\e[91mSomething went wrong! Checks the logs above\e[0m\n"; exit 1; fi

      ## Setup git with the given Credentials
      ##
      git config user.name "$GIT_USER"
      git config user.email "$GIT_EMAIL"

      ## Recreate Index for the Pages index
      ##
      if ! cr index -c "$CR_REPO_URL" $CR_ARGS; then echo -e "\n\e[91mSomething went wrong! Checks the logs above\e[0m\n"; exit 1; fi

      ## Checkout the pages branch and
      ## add Index as new addition and make a signed
      ## commit to the origin
      ##
      git checkout -f gh-pages
      cp -f .cr-index/index.yaml index.yaml || true
      git add index.yaml
      git status
      git commit -sm "Update index.yaml"
      git push origin gh-pages

  else
    ## Some Feedback
    echo -e "\n\e[33mChanges to non existent chart detected.\e[0m\n"; exit 0;
  fi
else
  ## Some Feedback
  echo -e "\n\e[33mNo Changes on any chart detected.\e[0m\n"; exit 0;
fi
