function __switch_node_version --on-variable FNM_NODE_VERSION --on-variable PWD
  if test (type -t fnm) != "file"
    return
  end
  set -l node_version "$FNM_NODE_VERSION"
  if test -z "$node_version" -a -f .envrc
    set node_version (bash -c 'source .envrc 2>/dev/null && echo $FNM_NODE_VERSION')
  end
  if test -n "$node_version"
    fnm use "$node_version" --log-level=quiet
  else
    fnm use default --log-level=quiet
  end
end
