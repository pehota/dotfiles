function __switch_node_version --on-variable FNM_NODE_VERSION --on-variable PWD
  if test (type -t fnm) != "file"
    return
  end
  if test "$FNM_NODE_VERSION" != ""
    fnm use "$FNM_NODE_VERSION" --log-level=quiet
  else
    fnm use default --log-level=quiet
  end
end
