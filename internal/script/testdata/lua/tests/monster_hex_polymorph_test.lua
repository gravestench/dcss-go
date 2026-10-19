
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local polymorph = require("policy.combat.monster_hexes.polymorph")

local test = {}

-- Monster Polymorph uses the source legal-form check.
function test.run()
    local ctx = {}
    local foe = 202

    -- Deny optional forms so the legal-form test uses the configured monster kind.
    function ctx:has()
        return false
    end

    -- Return the rat target definition for the polymorph eligibility branch.
    function ctx:get(entity, id)
        if entity == foe and id == component.ACTOR then
            return {
                kind_id = monsters.MONS_RAT,
            }
        end

        return nil
    end

    harness.truthy(polymorph.viable(ctx, 101, foe),
        "monster Polymorph uses the source legal-form check")
end

return test
