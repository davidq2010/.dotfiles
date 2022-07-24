#!/usr/bin/bash

# Ignore case in substring matching using regez operator =~
# https://unix.stackexchange.com/questions/132480/case-insensitive-substring-search-in-a-shell-script#:~:text=You%20can%20do%20case-insensitive%20substring%20matching%20natively%20in,string%20search%2C%20convert%20both%20to%20the%20same%20case.
shopt -s nocasematch

ORIGINAL_DIR=$(pwd)
# 0 means dry run
DRY_RUN=1

# Idea:
# *) Dict of binaries to its install/update command
# *) Create a graph of binaries to all the things that depend on it
# *) In the order of the topologically sorted graph run the install/update fn for each binary

# NVIM BINARIES
CURL=curl
NPM=npm
PYTHON=python
PIP=pip
DEBUGPY=debugpy
DOTNET=dotnet-sdk
TELESCOPE_DEPS=telescope_deps
STYLUA=stylua
ESLINT=eslint
CLANG=clang
GCC=gcc
CPPCHECK=cppcheck
PYLINT=pylint
NVIM=nvim

# Map binaries to their installation functions
# https://stackoverflow.com/questions/5672289/bash-pass-a-function-as-parameter
declare -A INSTALL_FNS=(
    [CURL]="install_curl"
    [NPM]="install_npm"
    [PYTHON]="install_python"
    [PIP]="install_pip"
    [DEBUGPY]="install_debugpy"
    [DOTNET]="install_dotnet"
    [TELESCOPE_DEPS]="install_telescope_deps"
    [STYLUA]="install_stylua"
    [ESLINT]="install_eslint"
    [CLANG]="install_clang"
    [GCC]="install_gcc"
    [CPPCHECK]="install_cppcheck"
    [PYLINT]="install_pylint"
    [NVIM]="install_nvim"
)

# Determine system package installer based on OS
# https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    # VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    # VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    # VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    # VER=$(cat /etc/debian_version)
elif [ -f /etc/arch_release ]; then
    OS=Arch
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    #VER=$(uname -r)
fi

if [[ $OS =~ "Arch" ]]; then
    # https://bbs.archlinux.org/viewtopic.php?id=191442
    PACMAN_PACKAGES=$(pacman -Ssq)
    # Could also use process substitution: sort -u <(wget -q -O - https://aur.archlinux.org/packages.gz | gunzip)
    # That last '-' means "end of options"
    AUR_PACKAGES=$(wget -q -O - https://aur.archlinux.org/packages.gz | gunzip | sort -u)
elif [[ $OS =~ "Ubuntu" || $OS =~ "Debian" ]]; then
    PYTHON=${PYTHON}3
    DOTNET=${DOTNET}-6.0
fi

# https://unix.stackexchange.com/questions/46081/identifying-the-system-package-manager
check_for_package_and_install() {
    local pkg=$1
    if [[ $OS =~ "Ubuntu" || $OS =~ "Debian" ]]; then
        # Only install if not on s ystem
        if [[ $(sudo dpkg -s "$pkg") != 0 ]]; then
            if [[ $(apt-cache search --names-only "^${pkg}$") == 0 ]]; then
                sudo apt-get --assume-yes --install-suggests install "$pkg"
            fi
        fi
    elif [[ $OS =~ "Arch" ]]; then
        # Only install if not on system
        if [[ $(pacman -Qi "$pkg") != 0 ]]; then
            if [[ $(echo "$PACMAN_PACKAGES" | grep "^${pkg}$") == 0 ]]; then
                yes | sudo pacman -S "$pkg"
            elif [[ $(echo "$AUR_PACKAGES" | grep "^${pkg}$") == 0 ]]; then
                [[ ! -d "$HOME/AURPackages" ]] && mkdir "$HOME/AURPackages"
                # If couldn't cd, return failure code
                cd "$HOME/AURPackages" || return 1
                git clone "https://aur.archlinux.org/${pkg}.git"
                cd "$pkg" || return 1
                makepkg -si
                cd "$ORIGINAL_DIR" || return 1
            fi
        fi
    fi
}

# Installation functions
install_curl () {
    echo Installing $CURL...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $CURL
    fi
}

install_npm () {
    echo Installing $NPM...
    # TODO: Update when necessary
    if [[ $DRY_RUN != 0 ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
        nvm install --lts
    fi
}

install_python () {
    echo Installing $PYTHON...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $PYTHON
    fi
}

install_pip () {
    echo Installing $PIP...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $PYTHON-$PIP
    fi
}

install_debugpy () {
    echo Installing $DEBUGPY...
    if [[ $DRY_RUN != 0 ]]; then
        [[ ! -d "$HOME/.virtualenvs" ]] && mkdir "$HOME/.virtualenvs"
        cd "$HOME/.virtualenvs" || return 1
        local create_venv_cmd
        create_venv_cmd="$PYTHON -m venv $DEBUGPY"
        if [[ $($create_venv_cmd) != 0 ]]; then
            # Need to install python*-venv
            # Get the * based on python* binary
            local path_to_curr_python
            # The 'python3' binary is usually symlinked to a different binary, like 'python3.10'
            path_to_curr_python=$(readlink -f "$(which $PYTHON)")
            local prefix
            prefix=${path_to_curr_python%%"${PYTHON}"*}
            local idx_of_substr
            idx_of_substr=${#prefix}
            check_for_package_and_install "${path_to_curr_python:$idx_of_substr}-venv"
            $create_venv_cmd
        fi
        $DEBUGPY/bin/$PYTHON -m pip install debugpy
        cd "$ORIGINAL_DIR" || return 1
    fi
}

install_dotnet () {
    echo Installing $DOTNET...
    if [[ $DRY_RUN != 0 ]]; then
        if [[ $OS =~ "Arch" ]]; then
            check_for_package_and_install $DOTNET
        elif [[ $OS =~ "Ubuntu" || $OS =~ "Debian" ]]; then
            wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            sudo apt-get install -y apt-transport-https && sudo apt-get update
            check_for_package_and_install ${DOTNET}
        fi
    fi
}

install_telescope_deps () {
    echo Installing $TELESCOPE_DEPS...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install ripgrep
        if [[ $OS =~ "Arch" ]]; then
            check_for_package_and_install fd
        elif [[ $OS =~ "Ubuntu" || $OS =~ "Debian" ]]; then
            check_for_package_and_install fd-find
            # b/c there's another package named fd
            ln -s "$(which fd-find)" ~/.local/bin/fd
        fi
    fi
}

install_stylua () {
    echo Installing $STYLUA...
    if [[ $DRY_RUN != 0 ]]; then
        curl -LO https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-linux.zip
        unzip $STYLUA-linux.zip
        chmod u+x $STYLUA
        sudo mv $STYLUA /usr/local/bin/$STYLUA
        rm $STYLUA-linux.zip
    fi
}

install_eslint () {
    echo Installing $ESLINT...
    if [[ $DRY_RUN != 0 ]]; then
        sudo npm install -g eslint
    fi
}

install_clang () {
    echo Installing $CLANG...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $CLANG
    fi
}

install_gcc () {
    echo Installing $GCC...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $GCC
    fi
}

install_cppcheck () {
    echo Installing $CPPCHECK...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $CPPCHECK
    fi
}

install_pylint () {
    echo Installing $PYLINT...
    if [[ $DRY_RUN != 0 ]]; then
        $PIP install $PYLINT
    fi
}

install_nvim () {
    echo Installing $NVIM...
    if [[ $DRY_RUN != 0 ]]; then
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
        chmod u+x nvim.appimage
        sudo mv nvim.appimage /usr/local/bin/nvim
    fi
}

# Determine order of installation based on dependency graph (DFS)
install_python
INSTALL_ORDER=$($PYTHON get_install_order.py NVIM_DEPENDENCIES.json)
for binary in $INSTALL_ORDER; do
    ${INSTALL_FNS[$binary]}
done
