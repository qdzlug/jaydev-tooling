#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=~/configs/dotfiles                    # dotfiles directory
olddir=~/.dotfiles_old             # old dotfiles backup directory
##files="bashrc vimrc vim viminfo zshrc aliases jay_aliases"    # list of files/folders to symlink in homedir

files="aliases atom bash_profile bashrc geeknote gitconfig jay_aliases tmux.conf vim viminfo zlogin zlogout zprofile zshenv zshrc tmuxinator"
##########

# create dotfiles_old in homedir
echo -n "Creating $olddir for backup of any existing dotfiles in ~ ..."
mkdir -p $olddir
echo "done"

# Link bin if it doesn't exist
if [[ ! -d ~/bin/ ]]; then
    ln -s ~/configs/bin ~/bin
fi


# change to the dotfiles directory
echo -n "Changing to the $dir directory ..."
cd $dir
echo "done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
for file in $files; do
    echo "Moving any existing dotfiles from ~ to $olddir"
    mv ~/.$file ~/dotfiles_old/
    echo "Creating symlink to $file in home directory."
    ln -s $dir/$file ~/.$file
done

install_zsh () {
# Test to see if zshell is installed.  If it is:
if [ -f /bin/zsh -o -f /usr/bin/zsh  -o -f /opt/local/bin/zsh ]; then
    # Clone my antigen repository from GitHub only if it isn't already present
    if [[ ! -d ~/antigen/ ]]; then
        cd ~ && git clone https://github.com/zsh-users/antigen.git
    fi
    # Set the default shell to zsh if it isn't currently set to zsh
    if [[ ! $(echo $SHELL) == $(which zsh) ]]; then
        chsh -s $(which zsh)
    fi
else
    # If zsh isn't installed, get the platform of the current machine
    platform=$(uname);
    # If the platform is Linux, try an apt-get to install zsh and then recurse
    if [[ $platform == 'Linux' ]]; then
        if [[ -f /etc/redhat-release ]]; then
            sudo yum install zsh
            install_zsh
        fi
        if [[ -f /etc/debian_version ]]; then
            sudo apt-get install zsh
            install_zsh
        fi
    # If the platform is OS X, tell the user to install zsh :)
    elif [[ $platform == 'Darwin' ]]; then
        echo "Please install zsh, then re-run this script!"
        exit
    fi
fi
}

install_jirash () {
    if [[ ! -d ~/bin/jirash/ ]]; then
	cd ~/bin && git clone https://github.com/trentm/jirash.git
    fi
}


link_ssh () {
        if [[ -f ~/.ssh/config ]]; then
            mv ~/.ssh/config ~/.ssh/config.save
	    ln -s ~/configs/ssh/config ~/.ssh/config
	else
	    ln -s ~/configs/ssh/config ~/.ssh/config
        fi
}

link_sdc () {
        if [[ -f ~/.sdc ]]; then
            mv ~/.sdc ~/.sdc.save
	    ln -s ~/configs/sdc ~/.sdc
	else
	    ln -s ~/configs/sdc ~/.sdc
        fi
}






install_zsh
link_ssh
link_sdc
