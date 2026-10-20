-- Open five-by-five demonic clearing; its center fog seed changes the otherwise bare floor.
-- Its named hook calls the shared source helper at this map's authored position.
local setup = require("policy.generation.vaults.serial.demonic_setup")
local handler = {}

handler.configure = setup.configure

return handler
