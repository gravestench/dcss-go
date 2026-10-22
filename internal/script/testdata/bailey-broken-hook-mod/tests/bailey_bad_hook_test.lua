-- Validate the real bundled DES against a deliberately incomplete mod hook.
local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- Startup validation must fail at the missing named method, before a
-- weighted map draw or a one-use outside portal transaction can happen.
function test.run()
    local path = "vaults/bailey/bailey_polearm_vampire_castle_hellmonk.des"
    local map = des.parse(path, mod.read(path))

    hooks.validate(map)
end

return test
