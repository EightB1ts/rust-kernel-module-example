#!/bin/bash

OS=''
VER=''
INPUT_NAME=''
DIR=$PWD

######### Script Functions #########

# Check for Rust Function
check_rust() {
    echo '🦀 Checking for Rusty Kernel & Compiler'
    if ! grep -q CONFIG_HAVE_RUST=y "/usr/src/linux/.config"; then
        echo '⛔ Non-Rusty Kernel. Is linux version 6.1+?  ⛔'
        exit
    fi

    if ! command -v rustc &> /dev/null; then
        echo '⛔ Could not locate Rust Compiler ⛔'
        echo 'Try running:'
        echo 'curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh'
        exit
    else
        echo '✅ Its Rusty!'
    fi
}

# Install Deps Function
install_deps() {
    echo '🏃 Installing Dependencies'

    if [[ $OS == 'Arch' ]]; then
        sudo pacman -S --noconfirm --needed git lld llvm
    elif [[ $OS == 'Ubuntu' ]]; then
        # NEED TO DETERMINE
        exit
    fi
}

# Get Kernel Source Function
get_kernel() {
    echo '⬇️  Downloading Kernel (This will take some time)'
    if [[ $OS == 'Arch' ]]; then
        git clone --depth 1 --branch v$VER https://github.com/archlinux/linux
        # cd linux
        # git fetch --all --tags --quiet
        # git checkout --quiet tags/v$VER 
        # cd ..
    elif [[ $OS == 'Ubuntu' ]]; then
        # NEED TO DETERMINE
        exit
    fi
}

# Prep Kernel Source Function
prep_kernel() {
    echo '👨‍🍳 Prepping Kernel'
    zcat /proc/config.gz > linux/.config
    sed -n '/^RUST=/{h;s/=.*/=y/};${x;/^$/{s//RUST=y/;H};x}' linux/.config
    cd linux
    make LLVM=1 menuconfig
    rustup override set $(scripts/min-tool-version.sh rustc)
    cargo install --locked --version $(scripts/min-tool-version.sh bindgen) bindgen
    rustup component add rust-src
    rustup component add rustfmt
    rustup component add clippy
    if [[ $(make LLVM=1 rustavailable) != 'Rust is available!' ]]; then
        echo '⛔ Kernel Prep Failed - Rust ⛔'
        exit
    fi

    echo '🏗️  Building Kernel (This will take time and resources)'
    make LLVM=1 -j$(nproc) >/dev/null

    if [ ! -f "scripts/target.json" ]; then
        echo '⛔ Kernel Prep Failed - Bad Make Config? ⛔'
        exit
    fi

    cd ..
}

# Generate Build Files Function
generate_buildfiles () {
    echo '✏️  Provide kernel module name [a-Z]: '
    read INPUT_NAME

    pattern='^[a-zA-Z]+$'
    if [[ $INPUT_NAME != '' && $INPUT_NAME =~ $pattern ]]; then
        echo '⚙️  Generating Makefile & Kbuild for:' $INPUT_NAME
        # Kbuild
        cat > 'src/Kbuild' << KBUILD
# SPDX-License-Identifier: GPL-2.0
obj-m := $INPUT_NAME.o      
KBUILD
        # Makefile
        cat > 'src/Makefile' << MAKEFILE
# SPDX-License-Identifier: GPL-2.0
MAKEFILE
    else
        echo '⛔ Invalid Module Name ⛔'
        exit
    fi
    
}

# Build Example Function
build_example() {
    echo '⚒️  Building Example'

    cd src
    mv rustexample.rs $INPUT_NAME.rs 2>/dev/null; true
    make -C ../linux LLVM=1 M=$PWD
    mv $INPUT_NAME.rs rustexample.rs 2>/dev/null; true
    rm -r *.c
    rm -r *.symvers
    rm -r *.order
    rm -r *.mod
    rm -r *.o
    rm -r .*.cmd
    cd ..

}


######### Start Script #########

# Determine Distro
if type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)

    if [[ $OS == 'Arch' ]]; then
        IN=$(uname -r)
        IFS='-'; arrIN=($IN); unset IFS;

        if [ arrIN[0] ] && [ arrIN[1] ]; then
            VER=${arrIN[0]}-${arrIN[1]} 
        fi
    elif [[ $OS == 'Ubuntu' ]]; then
        # NEED TO DETERMINE
        exit
    fi

fi

if [[ $OS == 'Arch' ]] && [[ $VER != '' ]]; then
    echo 'Building for' $OS
    
    check_rust
    install_deps

    if [ ! -d "linux" ]; then
        get_kernel
    fi

    if [ ! -f "linux/scripts/target.json" ]; then
        prep_kernel
    fi

    generate_buildfiles
    build_example

else
    echo '⛔ Could not determine distro. Supported Distros: Arch ⛔'
    exit 
fi
