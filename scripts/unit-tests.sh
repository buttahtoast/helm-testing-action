
#!/bin/bash
. /scripts/helpers/base.sh
  
head "Installing Unit-Test Plugin"
helm plugin install https://github.com/quintush/helm-unittest > /dev/null 2>&1

head "Execute Unit-Tests"
for chart in ${INPUT_CHARTS}; do
  config_load "${chart}"
  if [ "${UNIT_TEST_DISABLE,,}" == "true" ]; then 
    log "${chart}" "${Green}Unit-Tests disabled${Off} ✔"; 
  else 
    log "${chart}" "${Yellow}Executing Unit-Tests${Off}"; 
    helm unittest --color -3 ${UNIT_TEST_ARGS} "${chart}"
    if [ $? -eq 0 ]; then 
      log "${chart}" "${Green}Unit-Tests succeded${Off} ✔"; 
    else
      log "${chart}" "${Red}Unit-Tests failed${Off} ❌";  
      if [ "${UNIT_TEST_ALLOW_FAIL,,}" == "true" ]; then 
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