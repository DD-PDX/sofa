#!/bin/zsh
cd /tmp/
rm -rf /tmp/sofa
git clone https://github.com/DD-PDX/sofa
echo "Exploit Check:"
zsh /tmp/sofa/tool-scripts/macOSActiveExploitCheck-NUMERIC-FACT.sh
echo "CVE Check:"
zsh /tmp/sofa/tool-scripts/macOSCVECheck-NUMERIC-FACT.sh
echo "Compatibility Check:"
zsh /tmp/sofa/tool-scripts/macOSCompatibilityCheck-FACT.sh
echo "Version Check:"
zsh /tmp/sofa/tool-scripts/macOSVersionCheck-FACT.sh
echo "Verbose CVE Check:"
zsh /tmp/sofa/tool-scripts/macOSCVECheck-FACT.sh