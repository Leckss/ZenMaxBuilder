#!/usr/bin/bash

# Copyright (c) 2021-2022 @grm34 Neternels Team
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


_install_dependencies() {

    # Set the package manager for each Linux distribution
    declare -A PMS=(
        [apt]="sudo apt install -y"
        [pkg]="_ pkg install -y"
        [pacman]="sudo pacman -S --noconfirm"
        [yum]="sudo yum install -y"
        [emerge]="sudo emerge -1 -y"
        [zypper]="sudo zypper install -y"
        [dnf]="sudo dnf install -y"
    )

    # Get current package manager cmd
    OS=(pacman yum emerge zypper dnf pkg apt)
    for PKG in "${OS[@]}"
    do
        if which "$PKG" &>/dev/null
        then
            IFS=" "
            PM="${PMS[${PKG}]}"
            read -ra PM <<< "$PM"
            break
        fi
    done

    # Install missing dependencies
    if [[ ${PM[3]} ]]
    then
        for PACKAGE in "${DEPENDENCIES[@]}"
        do
            if ! which "${PACKAGE/llvm/llvm-ar}" &>/dev/null
            then
                _ask_for_install_pkg
                if [[ $INSTALL_PKG == True ]]
                then
                    eval "${PM[0]/_/}" "${PM[1]}" \
                         "${PM[2]}" "${PM[3]}" "$PACKAGE"
                fi
            fi
        done
    else
        _error "$MSG_ERR_OS"
    fi
}


_clone_toolchains() {
    _clone_proton() {
        if [[ ! -d $PROTON_DIR ]]
        then
            export TC=${PROTON_DIR##*/}
            _ask_for_clone_toolchain
            if [[ $CLONE_TC == True ]]
            then
                git clone --depth=1 -b \
                    "$PROTON_BRANCH" \
                    "$PROTON_URL" \
                    "$PROTON_DIR"
            fi
        fi
    }
    _clone_gcc_arm() {
        if [[ ! -d $GCC_ARM_DIR ]]
        then
            export TC=${GCC_ARM_DIR##*/}
            _ask_for_clone_toolchain
            if [[ $CLONE_TC == True ]]
            then
                git clone --depth=1 -b \
                    "$GCC_ARM_BRANCH" \
                    "$GCC_ARM_URL" \
                    "$GCC_ARM_DIR"
            fi
        fi
    }
    _clone_gcc_arm64() {
        if [[ ! -d $GCC_ARM64_DIR ]]
        then
            export TC=${GCC_ARM64_DIR##*/}
            _ask_for_clone_toolchain
            if [[ $CLONE_TC == True ]]
            then
                git clone --depth=1 -b \
                    "$GCC_ARM64_BRANCH" \
                    "$GCC_ARM64_URL" \
                    "$GCC_ARM64_DIR"
            fi
        fi
    }
    case $COMPILER in
        Proton-Clang)
            _clone_proton
            ;;
        Eva-GCC)
            _clone_gcc_arm
            _clone_gcc_arm64
            ;;
        Proton-GCC)
            _clone_proton
            _clone_gcc_arm
            _clone_gcc_arm64
    esac
}


_clone_anykernel() {
    if [[ ! -d $ANYKERNEL_DIR ]]
    then
        _ask_for_clone_anykernel
        if [[ $CLONE_AK == True ]]
        then
            git clone -b \
                "$ANYKERNEL_BRANCH" \
                "$ANYKERNEL_URL" \
                "$ANYKERNEL_DIR"
        fi
    fi
}

