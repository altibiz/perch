{ self, ... }:

{
  systems = builtins.length self.lib3.defaults.systems == 4;
}
