#!/bin/zsh --no-rcs
#
# Downloads and runs the https://github.com/kirkpatrickprice/macos-auditor script.
#
#
#
scriptPath="/tmp/test_scripts.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/test_scripts.sh"
#
# Delete any old versions
rm -rf $scriptPath
#
# Download the script
/usr/bin/curl -L -s $scriptURL -o $scriptPath
#
# Make it executable
chmod a+x $scriptPath
#
# Run the script
/bin/zsh $scriptPath
