#!/usr/bin/bash

#    Copyright (c) 2022 @grm34 Neternels Team
#
#    Permission is hereby granted, free of charge, to any person
#    obtaining a copy of this software and associated documentation
#    files (the "Software"), to deal in the Software without restriction,
#    including without limitation the rights to use, copy, modify, merge,
#    publish, distribute, sublicense, and/or sell copies of the Software,
#    and to permit persons to whom the Software is furnished to do so,
#    subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be
#    included in all copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Shell color codes
RED="\e[1;31m"; GREEN="\e[1;32m"; YELLOW="\e[1;33m"
BLUE="\e[1;34m"; CYAN="\e[1;36m"; BOLD="\e[1;37m"; NC="\e[0m"


# Display script banner
_banner() {
    echo -e "${BOLD}
   ┌─────────────────────────────────────────────┐
   │ ┏┓╻┏━╸╺┳╸┏━╸┏━┓┏┓╻┏━╸╻  ┏━┓   ╺┳╸┏━╸┏━┓┏┓┏┓ │
   │ ┃┗┫┣╸  ┃ ┣╸ ┣┳┛┃┗┫┣╸ ┃  ┗━┓    ┃ ┣╸ ┣╸┫┃┗┛┃ │
   │ ╹ ╹┗━╸ ╹ ┗━╸╹┗╸╹ ╹┗━╸┗━╸┗━┛    ╹ ┗━╸╹ ╹╹  ╹ │
   └─────────────────────────────────────────────┘"
}


# Help (--help or -h)
_usage() {
    echo -e "
${BOLD}Usage:${NC} bash Neternels-Builder [OPTION] [ARGUMENT]

  ${BOLD}Options${NC}
    -h, --help                     show this message and exit
    -u, --update                   update script and toolchains
    -m, --msg     [message]        send message on Telegram
    -f, --file    [file]           send file on Telegram
    -z, --zip     [Image.gz-dtb]   create flashable zip

${BOLD}More information at: \
${CYAN}http://github.com/grm34/Neternels-Builder${NC}
"
}


# Ask some information
_prompt() {
    LENTH=${*}; COUNT=${#LENTH}
    echo -ne "\n${YELLOW}==> ${GREEN}${1} ${RED}${2}"
    echo -ne "${YELLOW}\n==> "
    for (( CHAR=1; CHAR<=COUNT; CHAR++ )); do echo -ne "-"; done
    echo -ne "\n==> ${NC}"
}


# Ask confirmation (Yes/No)
_confirm() {
    CONFIRM=True; COUNT=$(( ${#1} + 6 ))
    until [[ ${CONFIRM} =~ ^(y|n|Y|N|yes|no|Yes|No|YES|NO) ]] || \
            [[ ${CONFIRM} == "" ]]; do
        echo -ne "${YELLOW}\n==> ${GREEN}${1} ${RED}[Y/n]${YELLOW}\n==> "
        for (( CHAR=1; CHAR<=COUNT; CHAR++ )); do echo -ne "-"; done
        echo -ne "\n==> ${NC}"
        read -r CONFIRM
    done
}


# Select an option
_select() {
    COUNT=0
    echo -ne "${YELLOW}\n==> "
    for ENTRY in "${@}"; do
        echo -ne "${GREEN}${ENTRY} ${RED}[$(( ++COUNT ))] ${NC}"
    done
    LENTH=${*}; NUMBER=$(( ${#*} * 4 ))
    COUNT=$(( ${#LENTH} + NUMBER + 1 ))
    echo -ne "${YELLOW}\n==> "
    for (( CHAR=1; CHAR<=COUNT; CHAR++ )); do echo -ne "-"; done
    echo -ne "\n==> ${NC}"
}


# Display some notes
_note() {
    echo -e "${YELLOW}\n[$(date +%T)] ${CYAN}${1}${NC}"; sleep 1
}


# Display error
_error() {
    echo -e "\n${RED}Error: ${YELLOW}${*}${NC}"
}


# Check command status and exit on error
_check() {
    "${@}"; local STATUS=$?
    if [[ ${STATUS} -ne 0 ]]; then
        _error "${@}"
        _exit
    fi
    return "${STATUS}"
}


# Properly exit with 5s timeout
_exit() {

    # On build error send status and logs on Telegram
    if [[ ${START_TIME} ]] && [[ ! $BUILD_TIME ]] && \
            [[ ${BUILD_STATUS} == True ]]; then
        END_TIME=$(TZ=${TIMEZONE} date +%s)
        BUILD_TIME=$((END_TIME - START_TIME))

        _send_msg \
"<b>${CODENAME}-${LINUX_VERSION}</b> | Build failed to compile after \
$((BUILD_TIME / 60)) minutes and $((BUILD_TIME % 60)) seconds</code>"

        _send_build "${LOG}" "${CODENAME}-${LINUX_VERSION} build logs"
    fi

    # Get user inputs and add them to logfile
    set | grep -v "${EXCLUDE_VARS}" > buildervar
    printf "\n### USER INPUT LOGS ###\n" >> "${LOG}"
    diff bashvar buildervar | grep -E "^> [A-Z_]{3,18}=" >> "${LOG}"

    # Remove inputs files
    FILES=(bashvar buildervar linuxver)
    for FILE in "${FILES[@]}"; do
        if [[ -f ${FILE} ]]; then rm "${FILE}"; fi
    done

    # Kill the current child
    if [[ ${!} ]]; then
        kill -9 ${!}
    fi

    # Display timeout exit msg
    for (( SECOND=5; SECOND>=1; SECOND-- )); do
        echo -ne \
            "\r\033[K${BLUE}Exit Neternels-Builder in ${SECOND}s...${NC}"
        sleep 1
    done

    # Kill the script
    echo && kill -- ${$}
}


# Clean AnyKernel Folder
_clean_anykernel() {
    _note "Cleaning AnyKernel repository..."

    UNWANTED=(Image.gz-dtb init.spectrum.rc)
    for UW in "${UNWANTED[@]}"; do
        rm -f "${ANYKERNEL_DIR}/${UW}"
    done
    if [[ ! -f ${ANYKERNEL_DIR}/${TAG}-${CODENAME}-\
${LINUX_VERSION}-${DATE}-signed.zip ]]; then
        rm -f "${ANYKERNEL_DIR}/*.zip"
    fi
}


# Download show progress bar only
_wget() {
    wget -O "${1}" --quiet --show-progress "${2}"
}


# Say goodbye
_goodbye_msg() {
    echo -e "\n${RED}<| Neternels Team @ Development is Life |>${NC}"
}
