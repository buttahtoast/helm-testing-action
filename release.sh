#!/bin/bash
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
  rm -rf "${CR_RELEASE_LOCATION}" && mkdir -p "${CR_RELEASE_LOCATION}" ## Recreates Package Directory
  rm -rf .cr-index && mkdir -p .cr-index ## Recreates Index File
}

## Function: breakChart()
## Chart testing was interrupted/broken
##
breakChart() {
  CHARTS_ERR+=("${1}");
  log "Found problems when packaging ${1}. ${1} will be skipped for further checks" "${RED}"
}

## Function: log()
## Logs normal output
##
log() {
  COLOR=""
  [ -z "${2}" ] && COLOR="${NONE}" || COLOR="${2}"
  echo -e "$COLOR--- ${1}$NONE"
}

## Colors
## Different Colors Codes
NONE='\033[0m'
YLW='\033[1;33m'
BLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[1;32m'


## Chart Configuration
##
CONFIG_NAME=${INPUT_CHARTCONFIG:-".chart-config"}
CONFIG_SUPPORTED_VALUES=( "DISABLE" "SKIP_PUBLISH" "GENERATE_SCHEMA" "SCHEMA_VALUES" "SCHEMA_FORCE" "KUBE_LINTER_DISABLE" "KUBE_LINTER_CONFIG" "KUBE_LINTER_ALLOW_FAIL" "UNIT_TEST_DISABLE" "UNIT_TEST_ALLOW_FAIL")

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
export CR_REPO_URL="${INPUT_REPOSITORY:-https://$(cut -d '/' -f 1 <<< "$GITHUB_REPOSITORY").github.io/$(cut -d '/' -f 2 <<< "$GITHUB_REPOSITORY")/}";
export CR_REPO_URL="${CR_REPO_URL:?Missing required Variable}";

## Repository name under which the
## releases are created. The default configuration
## environment variable 'CR_GIT_REPO' is prefered over
## the input setting. If none of both is set, the script
## will exit.
##
export CR_OWNER="${CR_OWNER:-$(cut -d '/' -f 1 <<< "$GITHUB_REPOSITORY")}";
export CR_GIT_REPO="${CR_GIT_REPO:-$(cut -d '/' -f 2 <<< "$GITHUB_REPOSITORY")}";

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
[ -f "${CR_CONFIG_LOCATION}" ] && CR_ARGS="--config ${CR_CONFIG_LOCATION}";

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

## Dry Run Mode
##
DRY_RUN=${INPUT_DRYRUN}


## Install Helm Plugins
##
! [ "${INPUT_SCHEMADISABLE,,}" == "true" ] && helm plugin install https://github.com/karuppiah7890/helm-schema-gen > /dev/null 2>&1
! [ "${INPUT_UNITTESTDISABLE,,}" == "true" ] && helm plugin install https://github.com/quintush/helm-unittest > /dev/null 2>&1

## Git Tag Fetching
## For a comparison we just need the latest tag.
##
git fetch --tags
HEAD_REV=$(git rev-parse --verify HEAD);
LATEST_TAG_REV=$(git rev-parse --verify "$(latestTag)");

## Initialize for each directory a matching regex
## which finds changes in the diff statement
##
CHART_INDICATOR="$( echo ${CHART_ROOT%/} | tr -d '[:space:]' )/*/Chart.yaml"
CHANGED_CHARTS="${CHANGED_CHARTS} $(git diff --find-renames --name-only $LATEST_TAG_REV -- $CHART_INDICATOR | cut -d '/' -f 1-2 | uniq)"


## All changed charts are parsed as array
## Xargs is used to trim spaces left and right
##
IFS=' ' read -a PUBLISH_CHARTS <<< "$(echo ${CHANGED_CHARTS} | xargs )"

## Checks if there were any changes made
## Because the variable structing is not super clean
## I ended up with these two checks. Might be
## improved in the future
##
if [[ ${#PUBLISH_CHARTS[@]} -gt 0 ]]; then

  ## Check if charts exist as directory, this
   ## serves as simple handler when a chart is removed
   ## (if that's ever gonna happen).
   ##
   EXISTING_CHARTS=()
   for PRE_CHART in "${PUBLISH_CHARTS[@]}"; do
       TRIM_CHART="$(echo $PRE_CHART | xargs)"
       [ -d "$TRIM_CHART" ] && EXISTING_CHARTS+=("$TRIM_CHART")
   done

   ## Just to be sure, checking that the array
   ## is not empty
   ##
   if [[ ${#EXISTING_CHARTS[@]} -gt 0 ]]; then

      ## Create required directories
      ##
      createDirs

      ## Verify gh-pages branch
      ##
      if ! git show-ref -q remotes/origin/gh-pages; then
          echo -e "\n${RED}Missing gh-pages branch, please initialize the branch${NONE}"; exit 1;
      fi

      ## Starting iteration for each chart to be packaged
      ## with the helm built-in function.
      ##
      CHARTS_ERR=()
      echo -e "\n${GREEN}- Crafting Packages${NONE}"
      for CHART in "${EXISTING_CHARTS[@]}"; do
          echo -e "\n${YLW}-- Chart: $CHART${NONE}\n"

          ## Local Chart Config Defaults
          CHART_KUBE_LINTER_CONFIG="${CHART%/}/${KUBE_LINTER_CONFIG:-.kube-linter.yaml}"

          ## Lookup Release Configuration
          c_config="${CHART%/}/${CONFIG_NAME}"
          log "Configuration lookup ($c_config)"
          if [ -f "$c_config" ]; then
             log "Found Configuration"
             # shellcheck source=/dev/null
             source "$c_config"
          fi

          ## Filter disabled Charts
          if [[ "${DISABLE,,}" == "true" ]]; then
            log "Chart Disabled"
          else

            ##
            ## Preparation
            ##
            log "Updating Dependencies"
            if ! helm dependency update ${CHART}; then
              log "Encounterd problem updating dependencies. Will continue..." "${RED}"
            fi

            ##
            ## Kube Linter
            ##
            if [[ "${KUBE_LINTER_DISABLE,,}" == "true" || "${INPUT_KUBELINTERDISABLE,,}" == "true" ]]; then
              log "Kube-Linter Disabled"
            else
              log "Kube-Linter Enabled"
              EXTRA_ARGS=""
              if [ -f "${INPUT_KUBELINTERDEFAULTCONFIG}" ]; then
                EXTRA_ARGS="--config ${INPUT_KUBELINTERDEFAULTCONFIG}"
                log "Using Global Kube-Linter Config (${INPUT_KUBELINTERDEFAULTCONFIG})"
              else
                log "Global Kube-Linter Config not found (${INPUT_KUBELINTERDEFAULTCONFIG})" "${RED}"
              fi

              if [ -f "${CHART_KUBE_LINTER_CONFIG}" ]; then
                if [ -f "${INPUT_KUBELINTERDEFAULTCONFIG}" ]; then
                  log "Merge with Global Kube-Linter configuration"
                  if spruce merge ${INPUT_KUBELINTERDEFAULTCONFIG} ${CHART_KUBE_LINTER_CONFIG} > "${CHART%/}/merged-kube-linter"; then
                    EXTRA_ARGS="--config ${CHART%/}/merged-kube-linter"
                  else
                    breakChart "${CHART}" && break;
                  fi
                else
                  EXTRA_ARGS="--config ${CHART_KUBE_LINTER_CONFIG}"
                  log "Using Chart Kube-Linter Config (${CHART_KUBE_LINTER_CONFIG})"
                fi
              else
                log "Chart Kube-Linter Config not found (${CHART_KUBE_LINTER_CONFIG})";
              fi

              log "Running Kube-Linter" "${YLW}"
              if kube-linter lint ${EXTRA_ARGS} ${CHART}; then
                log "Kube-Linter Succeded" "${GREEN}"
              else
                if [[ -n "$KUBE_LINTER_ALLOW_FAIL" ]] || [[ -n "$INPUT_KUBELINTERALLOWFAILURE" ]]; then
                  log "Chart linting failed!" "${RED}"
                  breakChart "${CHART}" && break;
                else
                  log "Chart linting allowed to fail!" "${YLW}"
                fi
              fi
            fi

            ##
            ## Helm Unit Tests
            ##

            if [[ "${UNIT_TEST_DISABLE,,}" == "true" || "${INPUT_UNITTESTDISABLE,,}" == "true" ]]; then
              log "Helm Unit-Tests Disabled"
            else
              log "Helm Unit-Tests Enabled"
              log "Running Unit-Tests" "${YLW}"
              if helm unittest --color -3 ${UNIT_TEST_ARGS} "${CHART}"; then
                log "Unit-Tests Succeded" "${GREEN}"
              else
                if [[ "${UNIT_TEST_ALLOW_FAIL,,}" == "true" ]] || [[ "${INPUT_UNITTESTALLOWFAILURE,,}" == "true" ]]; then
                  log "Unit-Tests allowed to fail!" "${YLW}"
                else
                  log "Unit-Tests failed!" "${RED}"
                  breakChart "${CHART}" && break;
                fi
              fi
            fi

            ## Chart Schema Generator
            ${INPUT_SCHEMADISABLE}

            SCHEMA_PATH="${CHART%/}/values.schema.json"
            if [[ "${SCHEMA_ENABLE,,}" != "true" ]] || [[ "${INPUT_SCHEMADISABLE,,}" == "true" ]]; then
              log "Helm Schema Generator Disabled"
            else
              log "Helm Schema Generator Enabled"
              if ! [ -f "${SCHEMA_PATH}" ] || [[ "${SCHEMA_FORCE,,}" == "true" ]]; then
                log "Generating Values Schema" "${YLW}"
                if helm schema-gen "${CHART%/}/${SCHEMA_VALUES:values.yaml}" > "${SCHEMA_PATH}"; then
                  log "Generating Values Schema Succeded" "${GREEN}"
                else
                  if [[ "${SCHEMA_ALLOW_FAIL,,}" == "true" ]] || [[ "${INPUT_SCHEMAALLOWFAILURE,,}" == "true" ]]; then
                    log "Generating Values Schema allowed to fail!" "${YLW}"
                  else
                    log "Generating Values Schema failed!" "${RED}"
                    breakChart "${CHART}" && break;
                  fi
                fi
              else
                log "Skipping Values Schema"
              fi
            fi

            log "Creating Helm Package"
            if [ -z "$DRY_RUN" ]; then
             if [ "${SKIP_PUBLISH,,}" == "true" ]; then
               log "Skipping Publish"
             else
               if helm package $CHART --dependency-update --destination ${CR_RELEASE_LOCATION}; then
                 log "Generate Package" "${GREEN}"
               else
                 log "Generating Package failed!" "${RED}"
                 CHARTS_ERR+=("${CHART}");
               fi
             fi
            else
              log "Dry Run..."
            fi
          fi

          ## Unset Configuration Values
          unset $(echo ${CONFIG_SUPPORTED_VALUES[*]})
      done

      ## Check Chart Errors
      ##
      echo -e "\n\e[33m- Checking for Errors\e[0m\n"
      if [ ${#CHARTS_ERR[@]} -eq 0 ]; then
        echo -e "-- No Chart contained errors"
      else
        echo -e "\e[91mErrors found with charts (Check above output)\n----------------------------\e[0m"
        printf ' - %s  \n' "${CHARTS_ERR[@]}"
        echo -e "\e[91m---------------------------\e[0m\n"
        if [ -z "${INPUT_FORCE}" ]; then
          exit 1;
        else
          echo -e "-- Forcing Publish";
        fi
      fi


      ## For each package made by helm cr will
      ## create a helm release on the GitHub Repository
      ##
      echo -e "\n\e[33m- Creating Releases\e[0m\n"
      if [ -z "$DRY_RUN" ]; then
        if [ "$(ls -A ${CR_RELEASE_LOCATION})" ]; then
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
          echo "Nothing to release" && exit 0
        fi
      else
        echo -e "Dry Run...";
        exit 0;
      fi
    else
      ## Some Feedback
      echo -e "\n\e[33mChanges to non existent chart detected.\e[0m\n"; exit 0;
    fi
else
  ## Some Feedback
  echo -e "\n\e[33mNo Changes on any chart detected.\e[0m\n"; exit 0;
fi
