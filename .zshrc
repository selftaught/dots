export ZSH=~/.oh-my-zsh

ZSH_THEME="pygmalion"
ENABLE_CORRECTION="true"
HIST_STAMPS="mm-dd-yyyy"

#autoload -U bashcompinit
#bashcompinit

source $ZSH/oh-my-zsh.sh

function source_dot_files {
    for file in "$1/".{path,bash_prompt,exports,aliases,functions,extra}; do
        if [[ -f "$file" && -r "$file" ]]; then
            source $file;
        fi
    done
}

source_dot_files $HOME;
source_dot_files $DOTPATH;

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#
# Find any running ssh-agent processes from our proc list
#
SSH_AGENT_PROCS=$(pgrep 'ssh-agent' | tr -d '\n')

if [[ -z $SSH_AGENT_PROCS ]]; then
    echo -e "\e[92mStarting SSH agent!\e[0m"
    echo -e "\e[90m"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/bh
    ssh-add ~/.ssh/github
    echo -e "\e[0m"
fi

unset file;

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

[ -f ~/bin/iterm_utils ] && source ~/bin/iterm_utils

