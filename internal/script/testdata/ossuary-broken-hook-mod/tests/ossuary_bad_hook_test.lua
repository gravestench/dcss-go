-- Validate the effective source map against the overlaid handler. A
-- missing method must fail before an unlucky weighted draw selects it.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- The parser reads the real bundled DES; only its handler is overridden.
function test.run()
    local path = "vaults/ossuary/ossuary_the_hunt_dpeg.des"
    local map = des.parse(path, mod.read(path))

    hooks.validate(map)
end

return test
