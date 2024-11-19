#!/bin/zsh
#
#
runScript(){
# Download the script
/usr/bin/curl -L -s $scriptURL -o $scriptPath
#
# Make it executable
chmod a+x $scriptPath
#
# Run the script
/bin/zsh $scriptPath
}
#
cd /tmp/
rm -rf /tmp/*FACT.sh
echo "Exploit Check:"
scriptPath="/tmp/macOSActiveExploitCheck-NUMERIC-FACT.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/macOSActiveExploitCheck-NUMERIC-FACT.sh"
runScript
echo "CVE Check:"
scriptPath="/tmp/macOSCVECheck-NUMERIC-FACT.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/macOSCVECheck-NUMERIC-FACT.sh"
runScript
echo "Compatibility Check:"
scriptPath="/tmp/macOSCompatibilityCheck-FACT.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/macOSCompatibilityCheck-FACT.sh"
runScript
echo "Version Check:"
scriptPath="/tmp/macOSVersionCheck-FACT.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/macOSVersionCheck-FACT.sh"
runScript
echo "XProtect Version Check:"
scriptPath="/tmp/XProtectVersionCheck-FACT.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/XProtectVersionCheck-FACT.sh"
runScript
echo "macOS Displacement Check:"
scriptPath="/tmp/macOSVersionDisplacement-FACT.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/macOSVersionDisplacement-FACT.sh"
runScript
echo "Verbose CVE Check:"
scriptPath="/tmp/macOSCVECheck-FACT.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/macOSCVECheck-FACT.sh"
runScript
echo "Max Minor Version:"
scriptPath="/tmp/macOSMaxMinorVersionCheck-FACT.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/macOSMaxMinorVersionCheck-FACT.sh"
runScript
echo "Max Major Version:"
scriptPath="/tmp/macOSMaxMajorVersionCheck-FACT.sh"
scriptURL="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts/macOSMaxMajorVersionCheck-FACT.sh"
runScript