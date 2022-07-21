#!/usr/bin/bash

# Ignore case in substring matching using regez operator =~
# https://unix.stackexchange.com/questions/132480/case-insensitive-substring-search-in-a-shell-script#:~:text=You%20can%20do%20case-insensitive%20substring%20matching%20natively%20in,string%20search%2C%20convert%20both%20to%20the%20same%20case.
shopt -s nocasematch

ORIGINAL_DIR=$(pwd)
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

# Initial list of binaries to install but allow user to override
TO_INSTALL=("$CURL" "$NPM" "$PYTHON" "$PIP" "$DEBUGPY" "$DOTNET" "$TELESCOPE_DEPS" "$STYLUA" "$ESLINT" "$CPPCHECK" "$PYLINT" "$NVIM")

# Construct dependency graph
declare -A DEPENDENCIES=(
    [$NVIM]="$CURL $NPM $PYTHON $PIP $DEBUGPY $DOTNET $TELESCOPE_DEPS $STYLUA $ESLINT $CLANG $GCC $CPPCHECK $PYLINT"
    [$DEBUGPY]="$PYTHON $PIP"
    [$PYLINT]="$PYTHON $PIP"
    [$PYTHON]=""
    [$PIP]="$PYTHON"
    [$ESLINT]="$NPM"
    [$DOTNET]=""
    [$TELESCOPE_DEPS]=""
    [$STYLUA]="$CURL"
    [$CLANG]=""
    [$GCC]=""
    [$CPPCHECK]=""
    [$CURL]=""
    [$NPM]="$CURL"
)

# Map binaries to their installation functions
# https://stackoverflow.com/questions/5672289/bash-pass-a-function-as-parameter
declare -A INSTALL_FNS=(
    [$NPM]="install_npm"
    [$PYTHON]="install_python"
    [$PIP]="install_pip"
    [$DEBUGPY]="install_debugpy"
    [$DOTNET]="install_dotnet"
    [$TELESCOPE_DEPS]="install_telescope_deps"
    [$STYLUA]="install_stylua"
    [$ESLINT]="install_eslint"
    [$CLANG]="install_clang"
    [$GCC]="install_gcc"
    [$CPPCHECK]="install_cppcheck"
    [$PYLINT]="install_pylint"
    [$NVIM]="install_nvim"
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
    check_for_package_and_install curl
}

install_npm () {
    echo Installing $NPM...
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    nvm install --lts
}

install_python () {
    echo Installing $PYTHON...
    check_for_package_and_install $PYTHON
}

install_pip () {
    echo Installing $PIP...
    check_for_package_and_install $PYTHON-$PIP
}

install_debugpy () {
    echo Installing $DEBUGPY...
    [[ ! -d "$HOME/.virtualenvs" ]] && mkdir "$HOME/.virtualenvs"
    cd "$HOME/.virtualenvs" || return 1
    local create_venv_cmd
    create_venv_cmd="$PYTHON -m venv $DEBUGPY"
    if [[ $(create_venv_cmd) != 0 ]]; then
        local path_to_curr_python
        path_to_curr_python=$(readlink -f "$(which $PYTHON)")
        local prefix
        prefix=${path_to_curr_python%%"${PYTHON}"*}
        local idx_of_substr
        idx_of_substr=${#prefix}
        check_for_package_and_install "${path_to_curr_python:$idx_of_substr}-venv"
        create_venv_cmd
    fi
    $DEBUGPY/bin/$PYTHON -m pip install debugpy
    cd "$ORIGINAL_DIR" || return 1
}

install_dotnet () {
    echo Installing $DOTNET...
    if [[ $OS =~ "Arch" ]]; then
        check_for_package_and_install $DOTNET
    elif [[ $OS =~ "Ubuntu" || $OS =~ "Debian" ]]; then
        wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
        sudo apt-get install -y apt-transport-https && sudo apt-get update
        check_for_package_and_install ${DOTNET}
    fi
}

install_telescope_deps () {
    echo Installing $TELESCOPE_DEPS...
    check_for_package_and_install ripgrep
    if [[ $OS =~ "Arch" ]]; then
        check_for_package_and_install fd
    elif [[ $OS =~ "Ubuntu" || $OS =~ "Debian" ]]; then
        check_for_package_and_install fd-find
        # b/c there's another package named fd
        ln -s "$(which fdfind)" ~/.local/bin/fd
    fi
}

install_stylua () {
    echo Installing $STYLUA...
    curl -LO https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-linux.zip
    unzip $STYLUA
    chmod u+x $STYLUA
    sudo mv $STYLUA /usr/local/bin/$STYLUA
    rm $STYLUA-linux.zip
}

install_eslint () {
    echo Installing $ESLINT...
    npm install -g eslint
}

install_clang () {
    echo Installing $CLANG...
    check_for_package_and_install $CLANG
}

install_gcc () {
    echo Installing $GCC...
    check_for_package_and_install $GCC
}

install_cppcheck () {
    echo Installing $CPPCHECK...
    check_for_package_and_install $CPPCHECK
}

install_pylint () {
    echo Installing $PYLINT
    $PIP install $PYLINT
}

install_nvim () {
    echo Installing $NVIM...
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim
}

# Determine order of installation based on dependency graph (DFS)
