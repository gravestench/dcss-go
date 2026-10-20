-- Sparse four-by-four graveyard patch with optional stones, graves, and plants.
-- Its named hook calls the shared source helper at this map's authored position.
local setup = require("policy.generation.vaults.serial.undead_setup")
local handler = {}

handler.configure = setup.configure

return handler
