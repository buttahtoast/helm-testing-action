#!/bin/bash
CONFIG_SUPPORTED_VALUES=( "HELM_DOCS_DISABLE" "HELM_DOCS_ALLOW_FAIL" "KUBE_LINTER_DISABLE" "KUBE_LINTER_CONFIG" "KUBE_LINTER_ALLOW_FAIL" "UNIT_TEST_DISABLE" "UNIT_TEST_ARGS" "UNIT_TEST_ALLOW_FAIL");
CONFIG_NAME=".chart-config"

function config_unset {
  for config in "${CONFIG_SUPPORTED_VALUES[@]}"
  do
     unset "${config}"
  done
}

function config_load { 
  C_CONFIG="${1%/}/${CONFIG_NAME}" 
  echo -e "[${1}]: ${Yellow}Attempt to load config ($C_CONFIG)${Off}"   
  if [ -f "${C_CONFIG}" ]; then 
    echo -e "[${1}]: ${Green}Found configuration${Off} ✔" 
    source "${C_CONFIG}"
  else 
    echo -e "[${1}]: ${Green}No configuration found${Off} ✔"
  fi
}