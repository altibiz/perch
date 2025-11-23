{ ... }:

let
  removeAttrByPath =
    path: attrs:
    if path == [ ] then
      attrs
    else
      let
        key = builtins.head path;
        tail = builtins.tail path;
      in
      if tail == [ ] then
        builtins.removeAttrs attrs [ key ]
      else
        if attrs ? ${key} && builtins.isAttrs attrs.${key} then
          attrs // {
            ${key} = removeAttrByPath tail attrs.${key};
          }
        else
          attrs;
in
{
  flake.lib3.attrset.removeAttrByPath = removeAttrByPath;
}
