-- Tiny room whose haze and altered ground make a sparse demonic encounter.
-- Its named hook calls the shared source helper at this map's authored position.
local setup = require("policy.generation.vaults.serial.demonic_setup")
local handler = {}

handler.configure = setup.configure

return handler
