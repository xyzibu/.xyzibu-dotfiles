#!/usr/bin/env bash

# refer  spf13-vim bootstrap.sh

############################  SETUP PARAMETERS
app_name='xyzibu-dotfiles'
[ -z "$APP_PATH" ] && APP_PATH="$HOME/.xyzibu-dotfiles"
[ -z "$REPO_URI" ] && REPO_URI='https://github.com/xyzibu/.xyzibu-dotfiles.git'
[ -z "$REPO_BRANCH" ] && REPO_BRANCH='master'
debug_mode='0'
[ -z "$VUNDLE_URI" ] && VUNDLE_URI="https://github.com/VundleVim/Vundle.vim.git"
[ -z "$OH_MY_ZSH_URI" ] && OH_MY_ZSH_URI="https://github.com/robbyrussell/oh-my-zsh.git"

############################  BASIC SETUP TOOLS
msg() {
    printf '%b\n' "$1" >&2
}

success() {
    if [ "$ret" -eq '0' ]; then
        msg "\33[32m[✔]\33[0m ${1}${2}"
    fi
}

error() {
    msg "\33[31m[✘]\33[0m ${1}${2}"
    exit 1
}

debug() {
    if [ "$debug_mode" -eq '1' ] && [ "$ret" -gt '1' ]; then
        msg "An error occurred in function \"${FUNCNAME[$i+1]}\" on line ${BASH_LINENO[$i+1]}, we're sorry for that."
    fi
}

program_exists() {
    local ret='0'
    command -v $1 >/dev/null 2>&1 || { local ret='1'; }

    # fail on non-zero return value
    if [ "$ret" -ne 0 ]; then
        return 1
    fi

    return 0
}

program_must_exist() {
    program_exists $1

    # throw error on non-zero return value
    if [ "$?" -ne 0 ]; then
        error "You must have '$1' installed to continue."
    fi
}

variable_set() {
    if [ -z "$1" ]; then
        error "You must have your HOME environmental variable set to continue."
    fi
}

lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
    fi
    ret="$?"
    debug
}

############################ SETUP FUNCTIONS

do_backup() {
    if [ -e "$1" ] || [ -e "$2" ] || [ -e "$3" ] || [ -e "$4" ]; then
        msg "Attempting to back up your original configuration."
        today=`date +%Y%m%d_%s`
        for i in "$1" "$2" "$3" "$4"; do
            [ -e "$i" ] && [ ! -L "$i" ] && mv -v "$i" "$i.$today";
        done
        ret="$?"
        success "Your original configuration has been backed up."
        debug
   fi
}

sync_repo() {
    local repo_path="$1"
    local repo_uri="$2"
    local repo_branch="$3"
    local repo_name="$4"

    msg "Trying to update $repo_name"

    if [ ! -e "$repo_path" ]; then
        mkdir -p "$repo_path"
        git clone -b "$repo_branch" "$repo_uri" "$repo_path"
        ret="$?"
        success "Successfully cloned $repo_name."
    else
        cd "$repo_path" && git pull origin "$repo_branch"
        ret="$?"
        success "Successfully updated $repo_name"
    fi

    debug
}

create_symlinks() {
    local source_path="$1"
    local target_path="$2"

    lnif "$source_path/.vimrc"         "$target_path/.vimrc"
    lnif "$source_path/.vimrc.bundles" "$target_path/.vimrc.bundles"
    lnif "$source_path/.vimrc.before"  "$target_path/.vimrc.before"
    lnif "$source_path/.vim"           "$target_path/.vim"
    lnif "$source_path/.tmux.conf"     "$target_path/.tmux.conf"
    lnif "$source_path/.zshrc"         "$target_path/.zshrc"

    if program_exists "nvim"; then
        lnif "$source_path/.vim"       "$target_path/.config/nvim"
        lnif "$source_path/.vimrc"     "$target_path/.config/nvim/init.vim"
    fi

    ret="$?"
    success "Setting up configurtion symlinks."
    debug
}

setup_vundle() {
    local system_shell="$SHELL"
    export SHELL='/bin/sh'

    vim \
        -u "$1" \
        "+set nomore" \
        "+BundleInstall!" \
        "+BundleClean" \
        "+qall"

    export SHELL="$system_shell"

    success "Now updating/installing plugins using Vundle"
    debug
}

setup_zsh_plugins() {
    if [ -e $1 ]; then
        source $1
    fi

    ret="$?"
    success "Successfully set up zsh plugins"
    debug
}
############################ MAIN()
variable_set "$HOME"
program_must_exist "vim"
program_must_exist "git"

do_backup           "$HOME/.vim" \
                    "$HOME/.vimrc" \
                    "$HOME/.tmux.conf"\
                    "$HOME/.zshrc"

sync_repo           "$APP_PATH" \
                    "$REPO_URI" \
                    "$REPO_BRANCH" \
                    "$app_name"

sync_repo           "$HOME/.oh-my-zsh" \
                    "$OH_MY_ZSH_URI" \
                    "master" \
                    "oh-my-zsh"

sync_repo           "$HOME/.vim/bundle/Vundle.vim" \
                    "$VUNDLE_URI" \
                    "master" \
                    "vundle"

create_symlinks     "$APP_PATH" \
                    "$HOME"

setup_vundle        "$APP_PATH/.vimrc.bundles.default"

setup_zsh_plugins   "$APP_PATH/.zsh.conf" 
chsh -s /bin/zsh

msg             "\nThanks for installing $app_name."
