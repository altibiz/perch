{ lib, ... }:

{
  options.prefix.enableHello = lib.mkEnableOption "hello";

  config.prefix.enableHello = true;
}
