# Defined in /tmp/fish.ZNQe7H/__setup_ebot7_env.fish @ line 2
function __setup_ebot7_env --description 'Setup e-bot7 environment' --on-variable PWD
	status --is-command-substitution; and return
  if string match -q -- "*/ebot7*" $PWD
    echo "Setting shit up"
    # bass sh ~/Work/job/git/ebot7/bin/ebot7bashrc.sh
    source ~/Work/job/git/ebot7/bin/ebot7fish.fish
  end
end
