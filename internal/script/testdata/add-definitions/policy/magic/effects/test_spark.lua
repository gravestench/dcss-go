local spells = require("ids.spells")
local registry = require("policy.magic.effects.registry")

local effect = {}

function effect.resolve()
    return nil
end

registry.add(spells.SPELL_TEST_SPARK, {
    resolve = effect.resolve,
})

return effect
