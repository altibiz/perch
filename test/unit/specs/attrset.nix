{ self, ... }:

{
  remove_nested =
    let
      src = { a = { b = 1; c = 2; }; d = 3; };
      got = self.lib3.attrset.removeAttrByPath [ "a" "b" ] src;
    in
    got == { a = { c = 2; }; d = 3; };

  remove_top =
    let
      src = { a = 1; b = 2; };
      got = self.lib3.attrset.removeAttrByPath [ "a" ] src;
    in
    got == { b = 2; };

  noop_missing =
    let
      src = { a = { c = 2; }; d = 3; };
      got = self.lib3.attrset.removeAttrByPath [ "a" "b" ] src;
    in
    got == src;

  noop_intermediate_not_set =
    let
      src = { a = 1; b = { c = 2; }; };
      got = self.lib3.attrset.removeAttrByPath [ "a" "x" ] src;
    in
    got == src;

  empty_leaf =
    let
      src = { a = { b = 1; }; };
      got = self.lib3.attrset.removeAttrByPath [ "a" "b" ] src;
    in
    got == { a = { }; };

  deep =
    let
      src = { a = { b = { c = { d = 4; e = 5; }; }; }; z = 0; };
      got = self.lib3.attrset.removeAttrByPath [ "a" "b" "c" "d" ] src;
    in
    got == { a = { b = { c = { e = 5; }; }; }; z = 0; };

  idempotent =
    let
      src = { a = { b = 1; c = 2; }; };
      once = self.lib3.attrset.removeAttrByPath [ "a" "b" ] src;
      twice = self.lib3.attrset.removeAttrByPath [ "a" "b" ] once;
    in
    once == twice;

  lists_untouched =
    let
      src = { a = { b = 1; l = [ 1 2 3 ]; }; };
      got = self.lib3.attrset.removeAttrByPath [ "a" "b" ] src;
    in
    got == { a = { l = [ 1 2 3 ]; }; };

  missing_deep_no_change =
    let
      src = { a = { b = { c = 1; }; }; };
      got = self.lib3.attrset.removeAttrByPath [ "a" "x" "y" ] src;
    in
    got == src;

  remove_subattrset =
    let
      src = { a = { b = { x = 1; }; c = 2; }; };
      got = self.lib3.attrset.removeAttrByPath [ "a" "b" ] src;
    in
    got == { a = { c = 2; }; };
}
