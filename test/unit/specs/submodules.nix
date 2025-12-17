{ self, ... }:

let
  submodules = self.lib.submodules.make {
    flakeModules = {
      withConfig = {
        submodule = {
          value = 1;
        };
      };
      withoutConfig = {
        other = 2;
      };
    };
    specialArgs = { inherit self; };
    config = "submodule";
  };
in
{
  submodules_make_correct = submodules == {
    withConfig = {
      value = 1;
    };
  };
}
