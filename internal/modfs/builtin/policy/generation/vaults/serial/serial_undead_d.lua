-- Grave ring around a central gravestone; dark pebble floor distinguishes the center.
-- Its named hook calls the shared source helper at this map's authored position.
local setup = require("policy.generation.vaults.serial.undead_setup")
local handler = {}

handler.configure = setup.configure

return handler
