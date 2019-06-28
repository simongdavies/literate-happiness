#!/bin/bash
# Create a parameter.toml and credentials.yaml file for a CNAB bundle 
# Parses a bundle.json and generates a parameters.toml and credentials.yaml for the bundle

set -e 

PARAM_FILENAME="parameters.toml"
CRED_FILENAME="credentials.yaml"
BUNDLE_FILENAME="bundle.json"
VALIDATE=false
USE_ENV_VAR_AS_SOURCE=true
OVERWRITE_FILES=false
USAGE="Usage: generate-cnab-param-and-cred-files\\n\\t[-d do not use environment variables as source for values in generated files, by default files are generated with environment variables as source]\\n\\t[-v validate that the environment variables exists for bundle arguments, default is false]\\n\\t[-p parameters TOML file name, default is ./parameters.toml ]\\n\\t[-c credentials YAML file name, default is ./credentials.yaml]\\n\\t[-b bundle.json file name, default is ./bundle.json]\\n\\t[-f overwrite existing credntial and parameter files]\\n"

while getopts ":hp:c:b:vdf" opt; do
  case ${opt} in
    p) 
        PARAM_FILENAME="${OPTARG}"
        ;;
    f) 
        OVERWRITE_FILES=true
        ;;
    c) 
        CRED_FILENAME="${OPTARG}"
        ;;
    b) 
        BUNDLE_FILENAME="${OPTARG}"
        ;;
    v)
        VALIDATE=true
        ;;
    d)
        USE_ENV_VAR_AS_SOURCE=false
        ;;
    \?) 
        printf "${USAGE}"
        exit 0
        ;;
    h)  
        printf "${USAGE}"
        exit 0
        ;;
  esac
done

shift $((OPTIND -1))

# Look for parameters in the bundle.json and set them in a TOML File

# TODO Support File Source as well as ENV

if [[ (-f "${PARAM_FILENAME}" || -f "${CRED_FILENAME}") && ${OVERWRITE_FILES} = "false" ]]; then
  echo "Output file(s) already exist  use -f option to overwrite" 
  exit 1
fi

cat /dev/null > "${PARAM_FILENAME}"

PARAMETERS=$(cat ${BUNDLE_FILENAME}|jq '.parameters|keys|.[]' -r)

for PARAM in ${PARAMETERS};do 
  
  VAR=$(echo "${PARAM}"| awk '{print toupper($0)}')
  HASDEFAULTVALUE=$(cat ${BUNDLE_FILENAME}|jq --arg key "${PARAM}" '.parameters|.[$key]|has("defaultValue")')
  DEFAULTVALUE=""

  if [  "${HASDEFAULTVALUE}" = "true" ]; then
    DEFAULTVALUE=$(cat ${BUNDLE_FILENAME}|jq --arg key "${PARAM}" '.parameters|.[$key].defaultValue' -r)
  fi

  # Check if there is an ENV Variable with an UPPERCASE name matching the parameter name 
  if [[ -z ${!VAR:-} && ${HASDEFAULTVALUE} = "false" && ${USE_ENV_VAR_AS_SOURCE} = "true" ]]; then
    printf "Bundle parameter values file expects %s to be set using environment variable: %s\\n" "${PARAM}" "${VAR}"
    if [ ${VALIDATE} = "true" ]; then
      exit 1
    fi
  fi

  if [[ ${USE_ENV_VAR_AS_SOURCE} = "true" && ! -z ${!VAR:-} ]];  then
    echo "${PARAM}=${!VAR}" >> "${PARAM_FILENAME}"
  else
    echo "${PARAM}=${DEFAULTVALUE:-INSERT VALUE HERE}" >> "${PARAM_FILENAME}"
  fi
done

# Look credentials in the bundle.json and set them in a credentials file

cat /dev/null > "${CRED_FILENAME}"

echo "name: credentials" >> "${CRED_FILENAME}"
echo "credentials:" >> "${CRED_FILENAME}"

CREDENTIALS=$(cat ${BUNDLE_FILENAME}|jq '.credentials|keys|.[]' -r)

for CRED in ${CREDENTIALS}; do
    VAR=$(echo "${CRED}"| awk '{print toupper($0)}')
    if [ -z ${!VAR:-} ]; then
        printf "Bundle expects credential: %s to be set using environment variable: %s\\n" "${CRED}" "${VAR}"
        if [ ${VALIDATE} = true ]; then
          exit 1
        fi
    fi
    printf "%s name: %s \\n  source: \\n   env: %s \\n" "-" "${CRED}" "${VAR}" >> "${CRED_FILENAME}"
 
done