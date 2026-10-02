#!/bin/zsh
#
# Test harness for the SOFA Addigy facts.
#
# Runs under bash or zsh: some runners (Addigy included) invoke a script with
# bash regardless of the shebang, so this file avoids zsh-only syntax.
#
# Downloads each *-FACT.sh from the fork and runs it, reporting the value, the
# exit code, and anything written to stderr. Addigy runs facts as root and all
# of the scripts share one feed cache, so a bad cache makes every fact fail the
# same way. Run this as root to match how Addigy sees it:
#
#   sudo /bin/zsh test_script.sh
#
# Options:
#   --reset-cache   delete /private/var/tmp/sofa before testing (needs root)
#   -h, --help      this text
#
# A first run shows you the cache as it stands. If the facts fail there, re-run
# with --reset-cache: if that fixes them, the cache was the problem.

REPO_RAW="https://raw.githubusercontent.com/DD-PDX/sofa/main/tool-scripts"
CACHE_DIR="/private/var/tmp/sofa"
FEED_URL="https://sofafeed.macadmins.io/v1/macos_data_feed.json"
TMP_DIR="/tmp"

# Pin a known PATH. Most of the fact scripts call cut/grep/plutil by bare name,
# so an odd PATH changes the result. Addigy's agent context is closer to this
# than an interactive shell is.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

reset_cache=0
for arg in "$@"; do
  case "$arg" in
    --reset-cache) reset_cache=1 ;;
    -h|--help) /usr/bin/sed -n '3,19p' "$0" | /usr/bin/sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

# ── Preflight ────────────────────────────────────────────────────────────────
echo "===== Preflight ====="

running_as=$(/usr/bin/id -un)
if [[ $EUID -ne 0 ]]; then
    echo "User            : ${running_as}"
    echo "                  WARNING: not root. Addigy runs facts as root, and"
    echo "                  ${CACHE_DIR} is normally root-owned, so curl cannot"
    echo "                  refresh the cache here. Re-run with sudo for a result"
    echo "                  that matches what Addigy sees."
else
    echo "User            : ${running_as} (matches Addigy)"
fi

echo "macOS           : $(/usr/bin/sw_vers -productVersion)"
echo "Model           : $(/usr/sbin/sysctl -n hw.model)"
echo "PATH            : ${PATH}"

if [[ $reset_cache -eq 1 ]]; then
    if [[ $EUID -ne 0 && -e "$CACHE_DIR" ]]; then
        echo "Cache reset     : FAILED, need root to remove ${CACHE_DIR}"
    else
        /bin/rm -rf "$CACHE_DIR"
        echo "Cache reset     : removed ${CACHE_DIR}"
    fi
fi

if [[ -d "$CACHE_DIR" ]]; then
    echo "Cache dir       : $(/bin/ls -ld "$CACHE_DIR" | /usr/bin/awk '{print $1, $3":"$4}')"
    [[ -w "$CACHE_DIR" ]] && echo "                  writable by ${running_as}" \
                          || echo "                  NOT writable by ${running_as}"
    cache_json="${CACHE_DIR}/macos_data_feed.json"
    if [[ -f "$cache_json" ]]; then
        bytes=$(/usr/bin/stat -f%z "$cache_json")
        if /usr/bin/plutil -extract "UpdateHash" raw "$cache_json" >/dev/null 2>&1; then
            echo "Cached feed     : ${bytes} bytes, parses OK"
        else
            echo "Cached feed     : ${bytes} bytes, DOES NOT PARSE  <-- likely cause of"
            echo "                  every fact failing. Re-run with --reset-cache."
        fi
    else
        echo "Cached feed     : absent (will be downloaded)"
    fi
else
    echo "Cache dir       : absent (will be created)"
fi

feed_code=$(/usr/bin/curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
            --header "User-Agent: SOFA-test-script" "$FEED_URL")
if [[ "$feed_code" == "200" ]]; then
    echo "Feed reachable  : yes (HTTP 200)"
else
    echo "Feed reachable  : NO (HTTP ${feed_code}) <-- check network, proxy or filtering"
fi
echo

# ── Fact scripts ─────────────────────────────────────────────────────────────
runScript() {
    local label="$1" script="$2"
    local path="${TMP_DIR}/${script}"
    local http out err rc errfile

    http=$(/usr/bin/curl -L -s -w '%{http_code}' "${REPO_RAW}/${script}" -o "$path")
    if [[ "$http" != "200" ]]; then
        printf '%-42s DOWNLOAD FAILED (HTTP %s)\n' "$label" "$http"
        printf '%-42s   script renamed or deleted in the fork?\n' ""
        return
    fi

    /bin/chmod a+x "$path"
    errfile=$(/usr/bin/mktemp)
    out=$(/bin/zsh "$path" 2>"$errfile")
    rc=$?
    # Every script cats and rms the etag temp file unconditionally, but curl only
    # writes it when the ETag changed. That noise is benign and appears on every
    # fact, so drop it here or it masks the errors worth seeing.
    err=$(/usr/bin/grep -v 'macos_data_feed_etag_temp.txt: No such file or directory' "$errfile")
    /bin/rm -f "$errfile"

    if [[ $rc -eq 0 ]]; then
        printf '%-42s %s\n' "$label" "${out:-(no output)}"
    else
        printf '%-42s %s   [exit %d]\n' "$label" "${out:-(no output)}" "$rc"
    fi
    [[ -n "$err" ]] && printf '%-42s   stderr: %s\n' "" "${err//$'\n'/; }"
    return 0
}

echo "===== Facts ====="
/usr/bin/find "${TMP_DIR}" -maxdepth 1 -name '*-FACT.sh' -delete 2>/dev/null

runScript "Exploit Check"                  "macOSActiveExploitCheck-NUMERIC-FACT.sh"
runScript "CVE Check"                      "macOSCVECheck-NUMERIC-FACT.sh"
runScript "Compatibility Check"            "macOSCompatibilityCheck-FACT.sh"
runScript "Compatibility Displacement"     "macOSCompatibilityDisplacement-FACT.sh"
runScript "Version Check"                  "macOSVersionCheck-FACT.sh"
runScript "XProtect Version Check"         "XProtectVersionCheck-FACT.sh"
runScript "macOS Displacement Check"       "macOSVersionDisplacement-FACT.sh"
runScript "Max Minor Version"              "macOSMaxMinorVersionCheck-FACT.sh"
runScript "Max Major Version"              "macOSMaxMajorVersionCheck-FACT.sh"
runScript "Latest Minor Version Installed" "macOSLatestMinorVersionCheck-FACT.sh"

echo
echo "Values above are raw script stdout. Addigy coerces these to the fact's"
echo "declared type, so a human-readable string on a number or boolean fact"
echo "becomes 'error parsing ... value' in the console."
