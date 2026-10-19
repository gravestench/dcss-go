-- The modded Test Spark effect tests spell dispatch by a newly registered id.
-- Example: resolving SPELL_TEST_SPARK completes successfully without a world effect.

local spells = require("ids.spells")
local registry = require("policy.magic.effects.registry")

local effect = {}

-- Return a successful no-op resolution: this fixture tests whether a newly
-- registered spell reaches Lua dispatch, not whether it changes world state.
function effect.resolve()
    return nil
end

registry.add(spells.SPELL_TEST_SPARK, {
    resolve = effect.resolve,
})

return effect
