
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local paralyse = require("policy.combat.monster_hexes.paralyse")
local strip = require("policy.combat.monster_hexes.strip_willpower")

local test = {}

-- Strip Willpower bypasses willpower one third of the time.
function test.run()
    local caster = 101
    local defender = 202
    local ctx = {}

    -- Return the floating-eye caster definition for Strip Willpower exception checks.
    function ctx:get(entity, id)
        if entity == caster and id == component.ACTOR then
            return {
                kind_id = monsters.MONS_FLOATING_EYE,
            }
        end

        return nil
    end

    -- Choose the bypass branch of the one-in-three willpower roll.
    function ctx:random(_, bound)
        return 0
    end

    harness.falsy(paralyse.resisted(ctx, caster, defender, {}),
        "floating eye paralysis bypasses the saving throw")
    harness.falsy(strip.resisted(ctx, caster, defender, {}),
        "Strip Willpower bypasses willpower one third of the time")
end

return test
