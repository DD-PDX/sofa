#!/bin/zsh --no-rcs
# shellcheck shell=bash

# Return the displacement between the maximum macOS version compatible with
# this hardware and the latest available major macOS version.
#
# Unlike macOSVersionDisplacement (which compares installed vs. latest),
# this fact compares what the hardware *can* run vs. what is current.
# A result of 0 means the hardware supports the latest macOS release.
# A result of 1 means the hardware tops out at n-1, etc.
#
# Apple will not release software updates for macOS versions with a
# displacement greater than 2 (n-2) and many software vendors will also
# cease support.
#
# To scope computers whose hardware cannot run the latest macOS:
#
#   macOS Compatibility Displacement - greater than - 0
#
#################################################
# EA script modified for use as an Addigy fact. #
#  - Removed verbose output                     #
#  - Set exits for errors to exit 1             #
#  - Changed output to a numeric displacement   #
#  - Accounts for macOS 15 → 26 version jump    #
#################################################

# Get current system OS
system_version=$( /usr/bin/sw_vers -productVersion )
# system_version=14.1  # UNCOMMENT TO TEST OLDER VERSIONS
system_os=$( /usr/bin/cut -d. -f1 <<< "$system_version" )

if [[ $system_os -ge 12 ]]; then
    # use plistlib
    os_compatibility="current"
else
    # use python 2.7
    os_compatibility="legacy"
    python_path="/usr/bin/python"
fi

# URL to the online JSON data
online_json_url="https://sofafeed.macadmins.io/v1/macos_data_feed.json"
user_agent="SOFA-Jamf-EA-macOSCompatibilityDisplacement/1.0"

# Local store
json_cache_dir="/private/var/tmp/sofa"
json_cache="$json_cache_dir/macos_data_feed.json"
etag_cache="$json_cache_dir/macos_data_feed_etag.txt"
etag_cache_temp="$json_cache_dir/macos_data_feed_etag_temp.txt"

# Ensure local cache folder exists
/bin/mkdir -p "$json_cache_dir"

# Check local vs online using etag (only available on macOS 12+)
if [[ -f "$etag_cache" && -f "$json_cache" ]]; then
    etag_old=$(/bin/cat "$etag_cache")
    /usr/bin/curl --compressed --silent --etag-compare "$etag_cache" --etag-save "$etag_cache_temp" --header "User-Agent: $user_agent" "$online_json_url" --output "$json_cache"
    etag_temp=$(/bin/cat "$etag_cache_temp")
    if [[ "$etag_old" == "$etag_temp" || $etag_temp == "" ]]; then
#         echo "Cached ETag matched online ETag - cached json file is up to date"
        /bin/rm "$etag_cache_temp"
    else
#         echo "Cached ETag did not match online ETag, so downloaded new SOFA json file"
        /bin/mv "$etag_cache_temp" "$etag_cache"
    fi
elif [[ "$os_compatibility" == "legacy" ]]; then
#     echo "OS not compatible with e-tags, proceeding to download SOFA json file"
    /usr/bin/curl --compressed --location --max-time 3 --silent --header "User-Agent: $user_agent" "$online_json_url" --output "$json_cache"
else
#     echo "No e-tag or SOFA json file cached, proceeding to download SOFA json file"
    /usr/bin/curl --compressed --location --max-time 3 --silent --header "User-Agent: $user_agent" "$online_json_url" --etag-save "$etag_cache" --output "$json_cache"
fi

if [[ ! -f "$json_cache" ]]; then
    echo "Could not obtain data"
    exit 1
elif [[ "$os_compatibility" == "legacy" ]]; then
    if ! "$python_path" -c 'import sys, json; print json.load(sys.stdin)["UpdateHash"]' < "$json_cache" > /dev/null; then
        echo "Could not obtain data"
        exit 1
    fi
elif ! /usr/bin/plutil -extract "UpdateHash" raw "$json_cache" > /dev/null; then
    echo "Could not obtain data"
    exit 1
fi

# Get model (DeviceID)
model=$(/usr/sbin/sysctl -n hw.model)
if [[ -z "$model" ]]; then
    echo "Could not obtain model"
    exit 1
fi
# echo "Model Identifier: $model"

# Check that the model is virtual or is in the feed at all
if [[ $model == "VirtualMac"* ]]; then
    # if virtual, we need to arbitrarily choose a model that supports all current OSes. Plucked for an M1 Mac mini
    model="Macmini9,1"
elif ! grep -q "$model" "$json_cache"; then
    echo "Unsupported Hardware"
    exit 1
fi

# Get the latest macOS major version and the max compatible major version for this model
if [[ "$os_compatibility" == "current" ]]; then
    os_version=$( /usr/bin/plutil -extract "OSVersions.0.Latest.ProductVersion" raw "$json_cache" | /usr/bin/head -n 1 | /usr/bin/grep -v "<stdin>" )
    # SupportedOS.0 returns "Name Version" e.g. "Tahoe 26" or "Sequoia 15"
    latest_compatible_os_string=$( /usr/bin/plutil -extract "Models.$model.SupportedOS.0" raw -expect string "$json_cache" | /usr/bin/head -n 1 )
else
    os_version=$( "$python_path" -c 'import sys, json; print json.load(sys.stdin)["OSVersions"][0]["Latest"]["ProductVersion"]' < "$json_cache" | /usr/bin/head -n 1 )
    latest_compatible_os_string=$( "$python_path" -c 'import sys, json; print json.load(sys.stdin)["Models"]["'$model'"]["SupportedOS"][0]' < "$json_cache" | /usr/bin/head -n 1 )
fi

latest_os=$( /usr/bin/cut -d. -f1 <<< "$os_version" )
# Extract the version number from the "Name Version" string
max_compatible_os=$( /usr/bin/cut -d' ' -f2 <<< "$latest_compatible_os_string" )
# echo "Latest Major Version: $latest_os"
# echo "Max Compatible Major Version: $max_compatible_os"

# Subtract 10 if the latest is 26 or greater and the max compatible OS is less than 26.
# This accounts for Apple's version numbering jump from macOS 15 to macOS 26.
if [[ "$latest_os" -ge 26 && "$max_compatible_os" -lt 26 ]]; then
    latest_os=$(( latest_os - 10 ))
fi

# Verify integers received from SOFA and output the result
if [[ "$((latest_os-latest_os))" == 0 && "$((max_compatible_os-max_compatible_os))" == 0 ]]; then
    echo "$((latest_os-max_compatible_os))"
else
    echo ""
fi
