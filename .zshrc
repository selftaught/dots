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

if [[ ! -z "$(which dircolors 2>/dev/null)" && -f "$HOME/.dircolors" ]]; then
    eval "$(dircolors $HOME/.dircolors)"
fi

#$HOME/bin/start-work-ssh-agent.sh

unset file;

