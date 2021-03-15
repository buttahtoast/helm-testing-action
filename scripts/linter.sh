#!/bin/bash
. /scripts/helpers/base.sh
LINTER_CONFIG_NAME=".kube-linter.yaml"
LINTER_EXTRA_ARGS=""

head "Initialize KubeLinter"
for chart in ${INPUT_CHARTS}; do
  config_load "${chart}"
  
  if [ "${KUBE_LINTER_DISABLE,,}" == "true" ]; then
    log "${chart}" "${Green}Kube-Linter disabled${Off} ✔"; 
  else 
    if [[ -f "./$LINTER_CONFIG_NAME" ]] && [[ -f "${chart}/$LINTER_CONFIG_NAME" ]]; then 
       spruce merge "./$LINTER_CONFIG_NAME" "${chart}/$LINTER_CONFIG_NAME" > "${chart%/}/.merged-kube-linter"
       LINTER_EXTRA_ARGS="--config ${chart%/}/.merged-kube-linter"
       log "${chart}" "${Yellow}Using Merged kube-linter configuration${Off}";
    elif [[ -f "./$LINTER_CONFIG_NAME" ]]; then 
       LINTER_EXTRA_ARGS="--config ./$LINTER_CONFIG_NAME"
       log "${chart}" "${Yellow}Using Global kube-linter configuration (./$LINTER_CONFIG_NAME)${Off}";
    elif [[ -f "${chart}/$LINTER_CONFIG_NAME" ]]; then
       LINTER_EXTRA_ARGS="--config ${chart}/$LINTER_CONFIG_NAME"
       log "${chart}" "${Yellow}Using Chart kube-linter configuration (${chart}/$LINTER_CONFIG_NAME)${Off}";
    fi

    log "${chart}" "${Yellow}Execute KubeLinter${Off}"; 
    kube-linter lint --verbose ${LINTER_EXTRA_ARGS} ${chart} 
    if [ $? -eq 0 ]; then 
      log "${chart}" "${Green}Kube-Linter succeded${Off} ✔"; 
    else 
      log "${chart}" "${Red}Kube-Linter failed${Off} ❌";
      if [ "${KUBE_LINTER_ALLOW_FAIL,,}" == "true" ]; then 
        log "${chart}" "${Yellow}Allowed to fail${Off} 💣";
      else 
        HAS_ERROR=1; 
      fi
    fi
  fi 
  echo "" 
  config_unset 
done 
summary