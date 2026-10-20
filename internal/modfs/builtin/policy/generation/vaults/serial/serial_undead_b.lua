-- Small four-by-four graveyard patch where withered plants may break the floor.
-- Its named hook calls the shared source helper at this map's authored position.
local setup = require("policy.generation.vaults.serial.undead_setup")
local handler = {}

handler.configure = setup.configure

return handler
