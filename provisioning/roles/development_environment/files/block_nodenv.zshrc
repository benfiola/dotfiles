export NODENV_ROOT=/opt/nodenv
export PATH=$NODENV_ROOT/bin:$PATH
eval "$(nodenv init -)"
export PATH=node_modules/.bin:$PATH