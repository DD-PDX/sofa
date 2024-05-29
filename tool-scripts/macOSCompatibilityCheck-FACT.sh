#!/bin/zsh --no-rcs
# shellcheck shell=bash

# Check if the model does support the latest version of macOS using SOFA
# by Balz Aschwanden
#
# adobted from the following script by Graham Pugh
# https://github.com/macadmins/sofa/blob/main/tool-scripts/macOSVersionCheck-EA.sh
#
# Updated for use with Addigy. - CH

# Note that this uses plutil so is only compatible with macOS 12+
#
# Use code inspired by the following post to exit if macOS < 12
# https://scriptingosx.com/2020/10/dealing-with-xpath-changes-in-big-sur/
#
# Modified from original which looked for less than 21H.
#
if [[ $(sw_vers -buildVersion) < "21D" ]]; then
    echo "<result>This EA only supports macOS 12+</result>"
    exit 1
fi

# URL to the online JSON data
online_json_url="https://sofa.macadmins.io/v1/macos_data_feed.json"
json_data=$(/usr/bin/curl -L -m 3 -s "$online_json_url")
if [[ ! "$json_data" ]]; then
    echo "<result>Could not obtain data</result>"
    exit 1
fi

# 1. Get model (DeviceID)
model=$(/usr/sbin/sysctl -n hw.model)
# echo "Model Identifier: $model"

# 2. identify the latest major OS
latest_os=$(/usr/bin/plutil -extract "OSVersions.0.OSVersion" raw -expect string - - <<< "$json_data" | /usr/bin/head -n 1)
# echo "Latest macOS: $latest_os"

# 3. idenfity latest compatible major OS
latest_compatible_os=$(/usr/bin/plutil -extract "Models.$model.SupportedOS.0" raw -expect string - - <<< "$json_data" | /usr/bin/head -n 1)
# echo "Latest Compatible macOS: $latest_compatible_os"

# 5. Compare latest with compatible
if [[ "$latest_os" == "$latest_compatible_os" ]];then
    echo "True"
else
    echo "False"
fi
