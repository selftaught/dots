export ZSH=~/.oh-my-zsh

ZSH_THEME="pygmalion"
ENABLE_CORRECTION="true"
HIST_STAMPS="mm-dd-yyyy"


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

unset file;


