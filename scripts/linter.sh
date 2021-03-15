#!/bin/bash
. /scripts/helpers/base.sh
LINTER_CONFIG_NAME=".kube-linter.yaml"
LINTER_CONFIG=""
LINTER_EXTRA_ARGS=""

head "Initialize KubeLinter"
for chart in ${INPUT_CHARTS}; do
  config_load "${chart}"
  
  if [ "${KUBE_LINTER_DISABLE,,}" == "true" ]; then
    log "${chart}" "${Green}Kube-Linter disabled${Off} ✔"; 
  else 
    if [[ -f "./$LINTER_CONFIG_NAME" ]] && [[ -f "${chart}/$LINTER_CONFIG_NAME" ]]; then 
       spruce merge "./$LINTER_CONFIG_NAME" "${chart}/$LINTER_CONFIG_NAME" > "./${chart%/}/merged-linter.yaml"
       if [ $? -eq 0 ]; then 
         LINTER_CONFIG="./${chart%/}/merged-linter.yaml"
       else 
         LINTER_CONFIG="./$LINTER_CONFIG_NAME"
         log "${chart}" "${Red}Merge failed! Using only global configuration (./$LINTER_CONFIG_NAME)${Off}";
       fi
    elif [[ -f "./$LINTER_CONFIG_NAME" ]]; then 
       LINTER_CONFIG="./$LINTER_CONFIG_NAME";
    elif [[ -f "${chart}/$LINTER_CONFIG_NAME" ]]; then
       LINTER_CONFIG="${chart}/$LINTER_CONFIG_NAME"
    fi

    if [ -f "${LINTER_CONFIG}" ]; then 
      log "${chart}" "${Yellow}Using Configuration ($LINTER_CONFIG):${Off}\n$(cat $LINTER_CONFIG | sed 's/^/  /')";
      LINTER_EXTRA_ARGS="--config $LINTER_CONFIG"
    else 
      log "${chart}" "${Red}Linter Configuration not found/invalid${Off}";
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