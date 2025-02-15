{ lib, ... }:

{
  options.prefix.enableHello = lib.mkEnable "hello";

  config.prefix.enableHello = true;
}
