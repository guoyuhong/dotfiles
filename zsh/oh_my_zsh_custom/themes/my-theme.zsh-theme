PROMPT_SUFFIX='%{$fg[yellow]%}%(?,,%{${fg[red]}%})$ %{$reset_color%}'
RPROMPT='%{$fg[green]%}%~%{$fg[black]%}|%{$fg[yellow]%}%*%{$reset_color%}'

_prompt_precmd() {
    local d root
    d=$PWD
    while : ; do
        if test -d "$d/.git" ; then
            root="$d/.git"
            break
        elif test -d "$d/.hg" ; then
            root="$d/.hg"
            break
        fi
        test "$d" = / && break
        d=$(cd -P "$d/.." && echo "$PWD")
    done

    local source_control_info
    if [[ -n "$root" ]]; then
        async_flush_jobs "my_prompt"
	    async_job "my_prompt" _get_source_control_prompt_info "$root"
        source_control_info="%{$fg[blue]%}...%{$fg[black]%}|"
    fi

   PROMPT="$source_control_info$PROMPT_SUFFIX"
}

_get_source_control_prompt_info() {
    local branch dirty
    builtin cd -q "$1/.."
    if [[ "$1" == *.git ]]; then
        branch=$(git_current_branch)
        dirty=$(command git status --porcelain 2> /dev/null | head -n1)
    elif [[ "$1" == *.hg ]]; then
        branch="master"
        local current="$1/bookmarks.current"
        if [[ -f "$current" ]]; then
            branch=$(cat "$current")
        fi
        dirty=$(command hg status 2> /dev/null | head -n1)
    fi

    if [[ -n "$dirty" ]]; then
        echo -n "%{$fg[red]%}$branch*%{$fg[black]%}|"
    else
        echo -n "%{$fg[blue]%}$branch%{$fg[black]%}|"
    fi
}

_prompt_callback() {
    if [[ -n "$3" ]]; then
        PROMPT="$3$PROMPT_SUFFIX"
        zle && zle reset-prompt
    fi
}

add-zsh-hook precmd _prompt_precmd

async_start_worker "my_prompt" -u -n
async_register_callback "my_prompt" _prompt_callback
