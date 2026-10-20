-- Lava-pair variant; preserve the two lava cells while scattering demonic ground.
-- Its named hook calls the shared source helper at this map's authored position.
local setup = require("policy.generation.vaults.serial.demonic_setup")
local handler = {}

handler.configure = setup.configure

return handler
