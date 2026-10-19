local beam = require("policy.combat.monster_beams")
local component = require("constants.component")
local harness = require("tests.harness")
local hexes = require("policy.combat.monster_hexes")
local mindburst = require("policy.combat.monster_hexes.mindburst")
local monsters = require("ids.monsters")

local test = {}

-- Keep contact hooks off a brainless target while checking the actual beam call boundary.
function test.run()
    local caster = 101
    local brainless = 202
    local original_resolve = beam.resolve
    local touched = false
    local ctx = {}

    -- Expose the brainless defender kind so the contact hook takes its exception path.
    function ctx:get(actor, id)
        if actor == brainless and id == component.ACTOR then
            return {
                kind_id = monsters.MONS_ABOMINATION_LARGE,
            }
        end

        return nil
    end

    -- Deny optional components to isolate the target-intelligence gate.
    function ctx:has()
        return false
    end

    -- Flag any emitted contact message; a skipped hook should leave it false.
    function ctx:emit()
        touched = true
    end

    -- The selected target may be valid, but Mindburst is a piercing beam.
    -- Each intervening contact must get its own brainlessness check.
    beam.resolve = function(_, _, _, profile, _, hook)
        hook.after_hit(ctx, caster, brainless, profile)

        return {}
    end

    hexes.resolve(ctx, caster, brainless, {}, {}, mindburst)

    beam.resolve = original_resolve

    harness.falsy(touched,
        "Mindburst cannot affect a brainless intervening contact")
end

return test
