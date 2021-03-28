function prompt_cwd() {
    echo -n "%{$fg_bold[blue]%}%d%{$reset_color%}" 
}

function prompt_git() {
    # check if in git working copy or in .git directory
    IN_WORK_TREE=$(command git rev-parse --is-inside-work-tree 2>/dev/null || echo "false")
    IN_DIR=$(command git rev-parse --is-inside-git-dir 2>/dev/null || echo "false")
    if [ "$IN_WORK_TREE" = "true" ] || [ "$IN_DIR" = "true" ]; then
        # in git repository
        # find branch name, determine color of branch display.
        DIRTY_FILES=$(command git status --porcelain --ignore-submodules -unormal 2>/dev/null || echo "")
        BRANCH=$(command git symbolic-ref --short HEAD 2>/dev/null || echo "")
        COMMIT=$(git log -n 1 --format="%h" 2>/dev/null || echo "")
        
        # assume dirty
        COLOR="%{$fg_bold[red]%}"

        if [ -z "$DIRTY_FILES" ]; then
            # no dirty files
            COLOR="%{$fg_bold[green]%}"
        fi

        if [ -z "$BRANCH" ]; then
            BRANCH="detached"
        fi

        # print git prompt
        echo -n " ${COLOR}[git::${BRANCH}(${COMMIT})]%{$reset_color%}"
    else
        # print nothing   
        echo -n ""
    fi
}

function prompt_caret() {
    echo -n "%{$fg_bold[grey]%}>%{$reset_color%} "
}

PROMPT='$(prompt_cwd)'
PROMPT+='$(prompt_git)'
PROMPT+=$'\n'
PROMPT+='$(prompt_caret)'
