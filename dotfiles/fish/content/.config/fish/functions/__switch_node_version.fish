function __switch_node_version --on-variable FNM_NODE_VERSION
  if test "$FNM_NODE_VERSION" != ""; and test (type -t fnm) = "file"
    fnm use "$FNM_NODE_VERSION"
  end
end
