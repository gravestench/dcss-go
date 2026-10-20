-- Small four-by-four demonic patch; trees and plants can interrupt its central haze.
-- Its named hook calls the shared source helper at this map's authored position.
local setup = require("policy.generation.vaults.serial.demonic_setup")
local handler = {}

handler.configure = setup.configure

return handler
