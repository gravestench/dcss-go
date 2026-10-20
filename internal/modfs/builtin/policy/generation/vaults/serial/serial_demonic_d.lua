-- A ring of bloody ground around a central altar-like glyph, with authored local substitutions.
-- Its named hook calls the shared source helper at this map's authored position.
local setup = require("policy.generation.vaults.serial.demonic_setup")
local handler = {}

handler.configure = setup.configure

return handler
