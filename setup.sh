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
CMAKE=cmake
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
ASCII_IMAGE=ascii-image-converter
NVIM=nvim
DIRENV=direnv

# Map binaries to their installation functions
# https://stackoverflow.com/questions/5672289/bash-pass-a-function-as-parameter
declare -A INSTALL_FNS=(
    [CURL]="install_curl"
    [CMAKE]="install_cmake"
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
    [ASCII_IMAGE]="install_ascii_image"
    [NVIM]="install_nvim"
    [DIRENV]="install_direnv"
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
        echo Installing using apt...
        # Only install if not on system
        if ! sudo dpkg -s "$pkg" > /dev/null 2>&1; then
            echo "$pkg is not already installed, trying to install from package manager"
            if apt-cache search --names-only "^${pkg}$" > /dev/null 2>&1; then
                echo "Installing $pkg from package manager"
                sudo apt --assume-yes --install-suggests install "$pkg"
            fi
        fi
    elif [[ $OS =~ "Arch" ]]; then
        echo Installing using pacman...
        # Only install if not on system
        if ! pacman -Qi "$pkg"; then
            echo "$pkg is not already installed, trying to install from package manager"
            if echo "$PACMAN_PACKAGES" | grep "^${pkg}$" > /dev/null 2>&1; then
                echo "Installing $pkg from pacman repo"
                yes | sudo pacman -S "$pkg"
            elif echo "$AUR_PACKAGES" | grep "^${pkg}$" > /dev/null 2>&1; then
                echo "Installing $pkg from AUR"
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
install_ascii_image() {
    echo Installing $ASCII_IMAGE
    #https://github.com/TheZoraiz/ascii-image-converter
    if [[ $DRY_RUN != 0 ]]; then
        if [[ $OS =~ "Arch" ]]; then
            check_for_package_and_install $ASCII_IMAGE-git
        elif [[ $OS =~ "Ubuntu" || $OS =~ "Debian" ]]; then
            filepath='/etc/apt/sources.list.d/ascii-image-converter.list'
            if [ ! -s $filepath ]; then
                echo hello
                echo 'deb [trusted=yes] https://apt.fury.io/ascii-image-converter/ /' | sudo tee $filepath
                sudo apt update
            fi
            check_for_package_and_install $ASCII_IMAGE
        fi
    fi
}

install_curl () {
    echo Installing $CURL...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $CURL
    fi
}

install_cmake () {
    echo Installing $CMAKE...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $CMAKE
    fi
}

install_npm () {
    echo Installing $NPM...
    if [[ $DRY_RUN != 0 ]]; then
        # TODO: Update when necessary
        nvm_ver="0.39.1"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        if ! command -v nvm >/dev/null 2>&1 || [[ $(nvm --version) != "$nvm_ver" ]]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$nvm_ver/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
        fi
        # If node is not installed or the latest lts node is not installed
        if (! command -v node >/dev/null 2>&1) || (! nvm ls lts/* >/dev/null 2>&1); then
            nvm install --lts
        fi
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
        echo "$PYTHON-$PIP"
        check_for_package_and_install "$PYTHON-$PIP"
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
            echo Need to install python*-venv
            # Need to install python*-venv
            # Get the * based on python* binary
            local path_to_curr_sys_python
            # The 'python3' binary is usually symlinked to a different binary, like 'python3.10'
            path_to_curr_sys_python=$(readlink -f /bin/$PYTHON)
            local prefix
            prefix=${path_to_curr_sys_python%%"${PYTHON}"*}
            local idx_of_substr
            idx_of_substr=${#prefix}
            echo Package to install: "${path_to_curr_sys_python:$idx_of_substr}-venv"
            check_for_package_and_install "${path_to_curr_sys_python:$idx_of_substr}-venv"
            $create_venv_cmd
        fi
        $DEBUGPY/bin/$PYTHON -m pip install debugpy
        cd "$ORIGINAL_DIR" || return 1
    fi
}

install_dotnet () {
    echo Installing $DOTNET...
    # Can see what outside apt repositories were added via /etc/apt/sources.list.d
    if [[ $DRY_RUN != 0 ]]; then
        # https://github.com/dotnet/core/issues/7699
        # Ubuntu 22.04 has dotnet now
        check_for_package_and_install $DOTNET
    fi
}

install_telescope_deps () {
    echo Installing $TELESCOPE_DEPS...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install ripgrep
        check_for_package_and_install fzf
        if [[ $OS =~ "Arch" ]]; then
            check_for_package_and_install fd
        elif [[ $OS =~ "Ubuntu" || $OS =~ "Debian" ]]; then
            check_for_package_and_install 'fd-find'
            # b/c there's another package named fd
            [ ! -d ~/.local/bin ] && mkdir ~/.local/bin
            if [ ! -s ~/.local/bin/fd ]; then
                ln -s "$(which fdfind)" ~/.local/bin/fd
            fi
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
        if ! command -v $ESLINT >/dev/null 2>&1; then
            sudo npm install --location=global $ESLINT
        fi
    fi
}

install_clang () {
    echo Installing $CLANG...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $CLANG
        if [[ $OS =~ "Arch" ]]; then
          check_for_package_and_install llvm
        fi
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

install_direnv () {
    echo Installing $DIRENV...
    if [[ $DRY_RUN != 0 ]]; then
        check_for_package_and_install $DIRENV
    fi
}

install_pylint () {
    echo Installing $PYLINT...
    if [[ $DRY_RUN != 0 ]]; then
        if ! command -v $PYLINT >/dev/null 2>&1; then
            $PIP install $PYLINT
        fi
    fi
}

install_nvim () {
    echo Installing $NVIM...
    if [[ $DRY_RUN != 0 ]]; then
        if [[ $OS =~ "Arch" ]]; then
            check_for_package_and_install fuse2
        elif [[ $OS =~ "Ubuntu" || $OS =~ "Debian" ]]; then
            check_for_package_and_install libfuse2
        fi
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
        chmod u+x nvim.appimage
        sudo mv nvim.appimage /usr/local/bin/nvim
    fi
}

# Determine order of installation based on dependency graph (DFS)
install_python
install_pip
$PIP install -U pytest
INSTALL_ORDER=$($PYTHON get_install_order.py NVIM_DEPENDENCIES.json)
echo "Install order: $INSTALL_ORDER"
for binary in $INSTALL_ORDER; do
    if ! ${INSTALL_FNS[$binary]}; then
        echo "Error installing $binary"
        exit 1
    fi
done

install_direnv
