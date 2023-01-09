#!/bin/bash

# $1 -> file, optional, otherwise take /mnt/output/yourTemplateNameHere.wmscript

FILE=${1:-/mnt/output/yourTemplateNameHere.wmscript}

if [ ! -f "${FILE}" ]; then
  echo "File does not exist: ${FILE}"
fi

ProductsLine=`cat ${FILE} | grep 'InstallProducts='`

re='(.*\.)([0-9]+)(\/.*)'

while [[ ${ProductsLine} =~ $re ]]; do
  ProductsLine="${BASH_REMATCH[1]}LATEST${BASH_REMATCH[3]}"
done

d=`date +%y-%m-%dT%H.%M.%S_%3N`
mv "${FILE}" "${FILE}.${d}.bak"

cat "${FILE}.${d}.bak" | grep -v 'InstallProducts=' > "${FILE}"

echo "${ProductsLine}" >> "${FILE}"
