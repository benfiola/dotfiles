export NODENV_ROOT=$HOME/.nodenv
export PATH=$NODENV_ROOT/bin:$PATH
eval "$(nodenv init -)"
export PATH=node_modules/.bin:$PATH