#!/bin/bash
set -e

FLAG=" --debug"

# Script to run duffle using ACI Driver in Docker
# All arguments are expected to be in ENV VARS
# Requires the following arguments plus any parameters/creds for the bundle 

parameterisrequired() {
    [[ (! $(cat bundle.json|jq --arg key "${param}" '.parameters|.[$key]|has("defaultValue")') == true ) || (($(cat bundle.json|jq --arg key "${param}" '.parameters|.[$key]|has("required")') == true)  ) && ($(cat bundle.json|jq -r --arg key "${param}" '.parameters[$key].required'|awk '{ print tolower($0) }') == "true") ]]
    return
}

# CNAB_INSTALLATION_NAME
# CNAB_ACTION
# CNAB_BUNDLE_NAME The anme os the bundle to install should be in the form of tool/bundlename (e.g porter/{name} or duffle/{name})
# ACI_LOCATION: The location to be used by the Duffle ACI Driver
# VERBOSE Enables Verbose output from the duffle ACI Driver

if [ -z "${CNAB_INSTALLATION_NAME}" ]; then 
    echo "Environment Variable CNAB_INSTALLATION_NAME} should be set to the name of the instance installed/updated/deleted" 
    exit 1
fi 

if [ -z "${CNAB_ACTION}" ]; then 
    echo "Environment Variable CNAB_ACTION should be set to the name of action to be taken on the instance" 
    exit 1
fi 

if [ -z "${CNAB_BUNDLE_NAME}" ]; then 
    echo "Environment Variable CNAB_BUNDLE_NAME should be set to the name of the bundle to be installed/updated/deleted" 
    exit 1
fi 

if [ -z "${ACI_LOCATION}" ]; then 
    echo "Environment Variable ACI_LOCATION should be set to the location to be used by the ACI Driver" 
    exit 1
fi 

if [[ ! ${VERBOSE} = "true" ]]; then 
    VERBOSE=false
    FLAG=""
fi



oras pull "${CNAB_QUICKSTART_REGISTRY:-"cnabquickstartstest.azurecr.io"}/${CNAB_BUNDLE_NAME}/bundle.json:latest"

# Look for parameters in the bundle.json and set them in a TOML File
# Expects to find parameter values in ENV variable named after the bundle parameter in UPPER case
# Ignores missing environment variables if the parameter has a default value

touch params.toml

parameters=$(cat bundle.json|jq '.parameters|keys|.[]' -r)


for param in ${parameters};do 
    
    # Its expcted that each parameters value is passed in using a correspondingly named variable, in some cases the bundle parameter name will not be a valid environment variable name
    # e.g. in cases where the parameter names are not defined in the bundle but are injected by the tool (e.g porter-debug)
    # These will get ignored if there are defaults 
    
    var=$(echo "${param^^}")

    if [[ ! $param =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then 
        if parameterisrequired; then
            printf "Bundle expects parameter: %s to be set but parameter name translates to illegal env var name: %s\\n" "${param}" "${var}"
            exit 1
        fi
        printf "Parameter %s has illegal ENV variable translation ignoring\\n" "${param}"
        continue
    fi
    
    if [ -z ${!var:-''} ]; then
        # Only require a value if parameter is required
         if parameterisrequired; then 
            printf "Bundle expects parameter: %s to be set using environment variable: %s\\n" "${param}" "${var}"
            exit 1
        fi
    else
        echo "${param}=\"${!var}\"" >> params.toml
    fi

done

# Look credentials in the bundle.json and set them in a credentials file
# Expects to find credentials values in ENV variable named after the bundle credential in UPPER case

touch credentials.yaml

echo "name: credentials" >> credentials.yaml
echo "credentials:" >> credentials.yaml

credentials=$(cat bundle.json|jq '.credentials|keys|.[]' -r)

for cred in ${credentials}; do
    var=$(echo "${cred^^}")
    if [ -z ${!var:-} ]; then
        printf "Bundle expects credential: %s to be set using environment variable: %s\\n" "${cred}" "${var}"
        exit 1
    else
        printf "%s name: %s \\n  source: \\n   env: %s \\n" "-" "${cred}" "${var}" >> credentials.yaml
    fi
done

export DUFFLE_HOME="${CNAB_STATE_MOUNT_POINT:-"/cnab/state"}/${CNAB_BUNDLE_NAME}/${CNAB_INSTALLATION_NAME}"
mkdir -p ${DUFFLE_HOME}
                   
duffle init

# TODO Support custom actions

case "${CNAB_ACTION}" in
    install)
        echo "Installing the Application"  
        duffle install "${CNAB_INSTALLATION_NAME}" bundle.json -f -d aci-driver -c ./credentials.yaml -p params.toml -v $FLAG >> /proc/1/fd/1
        ;;
    uninstall)
        echo "Destroying the Application"        
        duffle uninstall "${CNAB_INSTALLATION_NAME}" -d aci-driver -c ./credentials.yaml -p params.toml -v $FLAG >> /proc/1/fd/1
        ;;
    upgrade)
        echo "Upgrading the Application"
        duffle upgrade "${CNAB_INSTALLATION_NAME}" -d aci-driver -c ./credentials.yaml -p params.toml -v $FLAG >> /proc/1/fd/1
        ;;
    *)
        echo "No action for ${CNAB_ACTION}"
        ;;
esac

echo "Complete"