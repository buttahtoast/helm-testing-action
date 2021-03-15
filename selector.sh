#/bin/bash
EXECUTE=/scripts/${INPUT_EXEC:-docs}.sh
if [ -f "${EXECUTE}" ]; then 
  bash "${EXECUTE}"
else 
  echo "Script ${EXECUTE} not found!" && exit 1;
fi 