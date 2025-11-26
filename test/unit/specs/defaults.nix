{ self, ... }:

{
  defaults_systems_contains_4 = builtins.length self.lib3.defaults.systems == 4;
}
