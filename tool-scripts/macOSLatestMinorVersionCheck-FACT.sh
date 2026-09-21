#!/bin/zsh --no-rcs
# shellcheck shell=bash

# Check if the local system is running the latest minor version of the major
# macOS it already has installed, using SOFA.
#
# This deliberately ignores what the hardware could upgrade to. A Mac on the
# newest release of its current major OS returns True even when a newer major
# OS is available to it, e.g. 15.8, 26.7 and 27.0 are all True.
#
# For "is this Mac on the newest OS it could run", use
# macOSVersionCheck-FACT.sh instead.
#
# To use in a Smart Group to scope computers missing a minor update:
#   Running Latest Minor Version of Installed macOS - is - False
#
#################################################
# Written as an Addigy boolean fact.            #
#  - No verbose output                          #
#  - Set exits for errors to exit 1             #
#  - Output is boolean strings                  #
#################################################
#
# Note that this uses plutil so is only compatible with macOS 12+

# autoload is-at-least module for version comparisons
autoload is-at-least

# URL to the online JSON data
online_json_url="https://sofafeed.macadmins.io/v1/macos_data_feed.json"
user_agent="SOFA-Addigy-FACT-macOSLatestMinorVersionCheck/1.0"

# local store
json_cache_dir="/private/var/tmp/sofa"
json_cache="$json_cache_dir/macos_data_feed.json"
etag_cache="$json_cache_dir/macos_data_feed_etag.txt"
etag_cache_temp="$json_cache_dir/macos_data_feed_etag_temp.txt"

# ensure local cache folder exists
/bin/mkdir -p "$json_cache_dir"

# check local vs online using etag (only available on macOS 12+)
if [[ -f "$etag_cache" && -f "$json_cache" ]]; then
    etag_old=$(/bin/cat "$etag_cache")
    /usr/bin/curl --compressed --silent --etag-compare "$etag_cache" --etag-save "$etag_cache_temp" --header "User-Agent: $user_agent" "$online_json_url" --output "$json_cache"
    etag_temp=$(/bin/cat "$etag_cache_temp" 2>/dev/null)
    if [[ "$etag_old" == "$etag_temp" || $etag_temp == "" ]]; then
#         echo "Cached ETag matched online ETag - cached json file is up to date"
        /bin/rm -f "$etag_cache_temp"
    else
#         echo "Cached ETag did not match online ETag, so downloaded new SOFA json file"
        /bin/mv "$etag_cache_temp" "$etag_cache"
    fi
else
#     echo "No e-tag or SOFA json file cached, proceeding to download SOFA json file"
    /usr/bin/curl --compressed --location --max-time 3 --silent --header "User-Agent: $user_agent" "$online_json_url" --etag-save "$etag_cache" --output "$json_cache"
fi

if [[ ! -f "$json_cache" ]]; then
    echo "Could not obtain data"
    exit 1
elif ! /usr/bin/plutil -extract "UpdateHash" raw "$json_cache" > /dev/null; then
    echo "Could not obtain data"
    exit 1
fi

# 1. Get current system OS
system_version=$( /usr/bin/sw_vers -productVersion )
# system_version=14.1  # UNCOMMENT TO TEST OLDER VERSIONS
system_os=$(cut -d. -f1 <<< "$system_version")
# echo "System Version: $system_version"

# exit if less than macOS 12
if ! is-at-least 12 "$system_os"; then
    echo "Unsupported macOS"
    exit 1
fi

# 2. Find the feed entry for the major OS this Mac is already running.
# No model lookup is needed: what the hardware could upgrade to is irrelevant here.
# count the OSVersions entries rather than assuming a fixed number
os_versions_count=$(/usr/bin/plutil -extract "OSVersions" raw "$json_cache" | /usr/bin/head -n 1)
if [[ ! "$os_versions_count" =~ ^[0-9]+$ ]]; then
    echo "Could not obtain data"
    exit 1
fi

for (( i=0; i<os_versions_count; i++ )); do
    # OSVersion reads "Name Version", and the name can contain spaces
    # (e.g. "Golden Gate 27"), so take the last field
    os_version=$(/usr/bin/plutil -extract "OSVersions.$i.OSVersion" raw "$json_cache" | /usr/bin/head -n 1 | grep -v "<stdin>" | /usr/bin/awk '{print $NF}')
    if [[ "$os_version" == "$system_os" ]]; then
        product_version=$(/usr/bin/plutil -extract "OSVersions.$i.Latest.ProductVersion" raw "$json_cache" | /usr/bin/head -n 1)
#         echo "Latest Version of Installed macOS: $product_version"
        break
    fi
done

# the running major OS is not in the feed at all
if [[ -z "$product_version" ]]; then
    echo "Unsupported macOS"
    exit 1
fi

# 3. Compare the system against the latest release of its own major version.
# is-at-least is true when the system is at or ahead of the feed, so a build
# newer than the feed knows about (a beta or RC) still returns True.
if is-at-least "$product_version" "$system_version"; then
    echo "True"
else
    echo "False"
fi
