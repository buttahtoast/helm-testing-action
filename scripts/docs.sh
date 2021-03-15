#!/bin/bash
. /scripts/helpers/base.sh
DOC_CHARTS=()
  
## Create Documentation Checksum
head "Creating Checksums"
for chart in ${INPUT_CHARTS}; do
  config_load "${chart}"
  if [ "${HELM_DOCS_DISABLE,,}" == "true" ]; then 
    log "${chart}" "${Green}Helm-Docs disabled${Off} ✔"; 
  else 
    if [ -f "${chart%/}/README.md" ]; then 
      DOC_CHARTS+=(${chart})
      shasum ${chart%/}/README.md > ${chart%/}/README.md.sum
      log "${chart}" "${Green}Checksum created ($(cat ${chart%/}/README.md.sum))${Off} ✔";
    else
      log "${chart}" "${Yellow}No README.md file detected${Off} ❌";  
    fi
  fi  
  echo "" 
  config_unset
done 
  
if [ -n "${DOC_CHARTS}" ]; then 
  ## Execute helm-docs
  head "Executing Helm-Docs"
  helm-docs > /dev/null
  
  ## Check Checksums
  head "Validating Checksums"
  for chart in ${DOC_CHARTS[@]}; do
    config_load "${chart}"
    if [[ $(shasum "${chart%/}/README.md") == $(cat "${chart%/}/README.md.sum") ]]; then
      log "${chart}" "${Green}Documentation up to date${Off} ✔"
    else
      log "${chart}" "${Red}Checksums did not match - Documentation outdated!${Off} ❌\n  ${Red}Before:${Off} $(cat ${chart%/}/README.md.sum)\n  ${Red}After:${Off} $(shasum ${chart%/}/README.md)\n  ↳ ${Red}Execute helm-docs and push again${Off}"
      if [ "${HELM_DOCS_ALLOW_FAIL,,}" == "true" ]; then 
        log "${chart}" "${Yellow}Allowed to fail${Off} 💣";
      else 
        HAS_ERROR=1;
      fi 
    fi
    echo ""
    config_unset   
  done 
fi
summary