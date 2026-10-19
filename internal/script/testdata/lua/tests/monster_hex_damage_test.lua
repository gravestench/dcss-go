
local agony = require("policy.combat.monster_hexes.agony")
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local mindburst = require("policy.combat.monster_hexes.mindburst")
local monsters = require("ids.monsters")
local pain = require("policy.combat.monster_hexes.pain")
local spells = require("ids.spells")

local test = {}

local caster = 101
local foe = 202

-- Pain damage uses the source power floor for a weak caster.
function test.run()
    local ctx = {}

    -- Return the weak caster and defender definitions used by the Pain power calculation.
    function ctx:get(entity, id)
        if id == component.ACTOR then
            return {
                kind_id = entity == caster and monsters.MONS_ORC_WIZARD or
                    monsters.MONS_RAT,
            }
        end

        if entity == foe and id == component.HEALTH then
            return {
                current = 100,
                maximum = 100,
            }
        end

        return nil
    end

    -- Keep optional defensive components absent to isolate source power flooring.
    function ctx:has()
        return false
    end

    -- Use maximum damage dice to make the weak-power floor observable.
    function ctx:random(_, bound)
        return bound - 1
    end

    local agony_profile = catalog.get("monster_beams", spells.SPELL_AGONY)
    local pain_profile = catalog.get("monster_beams", spells.SPELL_PAIN)
    local mind_profile = catalog.get("monster_beams",
        spells.SPELL_MINDBURST)

    harness.truthy(agony.viable(ctx, caster, foe, agony_profile),
        "Agony selects a torment-vulnerable monster")
    harness.equal(agony.amount(ctx, caster, foe, agony_profile), 49,
        "Agony uses the source proportional torment loss")
    harness.equal(pain.amount(ctx, caster, foe, pain_profile), 14,
        "Pain damage uses the source power floor for a weak caster")
    harness.truthy(mindburst.amount(ctx, caster, foe, mind_profile) > 0,
        "Mindburst rolls its source monster damage dice")
end

return test
