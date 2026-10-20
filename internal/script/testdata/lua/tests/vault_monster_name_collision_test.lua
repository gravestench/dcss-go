-- A source vault's "shadow" means the ordinary monster, not a player shadow.
local harness = require("tests.harness")
local ids = require("ids.monsters")
local monster = require("policy.generation.vaults.specs.monster")
local resolve = require("policy.generation.vaults.specs.resolve")

local test = {}

-- Parse the authored MONS expression through production grammar, then
-- resolve its name against the live monster catalog and source spawn flags.
function test.run()
    local site = {
        path = "vaults/test/shadow.des",
        line = 1,
        vault_id = "shadow_test",
        directive = "MONS",
        glyph = "?",
    }
    local selected = monster.parse("shadow", site)[1][1]

    resolve.validate_monster(selected, site)

    local choice = resolve.monster({}, selected, 10, site)

    harness.equal(choice.kind_id, ids.MONS_SHADOW,
        "spawnable shadow wins the source name collision")
end

return test
