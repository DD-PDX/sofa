#!/bin/zsh --no-rcs
#
# Downloads and runs the https://github.com/kirkpatrickprice/macos-auditor script.
#
#
#
scriptPath="/tmp/test_scripts.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/test_scripts.sh"
# slackToken="xoxb-6508766112-6525785098051-NfPx5fsPei3mfmKclEnX11Q4"
epochTime=$( date +%s )
mySerial=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Serial\ Number\ \(system\)/ {print $NF}')
#
#
####################
# Logging Function #
####################
#
automa_superlogger() {
automa_log="/Library/Management/Automa/automa.log"
mkdir -p /Library/Management/Automa
touch $automa_log
echo -e "$(date +"%a %b %d %Y %T") $(hostname -s) $(basename "$0")[$$]: $*" | tee -a "${automa_log}"
}
#########################################
#
# Check that /Users/Shared/SendToDaVinci exists.  Warn and bail if it doesn't.
#
# mkdir -p /Users/Shared/SendToDaVinci
#
# Download the script
#
/usr/bin/curl -L -s $scriptURL -o $scriptPath
#
# Make it executable
chmod a+x $scriptPath
#
# Move to output directory 
# cd /Users/Shared/SendToDaVinci
#
# Run the script
/bin/zsh $scriptPath

# Zip up the file sin /Users/Shared/SendToDaVinci to /private/var/tmp
# zip -r /private/var/tmp/"$mySerial"_files.zip /Users/Shared/SendToDaVinci
#
#
# curl -F file=@/private/var/tmp/"$mySerial"_files.zip -F "initial_comment=Here are some files from "$mySerial"" -F channels=slackittome -H "Authorization: Bearer $slackToken" https://slack.com/api/files.upload