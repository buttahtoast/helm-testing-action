## Source: https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
# Color Presets
Off='\033[0m'             # Text Reset
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Base Variables 
HAS_ERROR=0 

# Check changed charts 
echo ""
if ! [ -n "${INPUT_CHARTS}" ]; then 
  echo -e "${Yellow}No Charts to process were given${Off}"
  summary 
fi 

# Configration Loader 
. /scripts/helpers/config.sh

# Helper Functions 

## Print Job Heading 
function head () {
  echo -e "💙 ${Yellow}${1}${Off}\n" 
}

## Chart Execution Log 
function log() {
  echo -e "[${1}]: ${2}"
}

## Print Summary
function summary() {
  head "Summary"
  if [ $HAS_ERROR -ne 0 ]; then
    echo -e "🏁 ${Red}Errors detected${Off} 👎" 
    exit 1
  else 
    echo -e "🏁 ${Green}No Errors detected${Off} 👍"
    exit 0;
  fi
}  

