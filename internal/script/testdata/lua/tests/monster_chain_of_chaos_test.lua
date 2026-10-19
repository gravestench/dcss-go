-- Chain of Chaos can revisit its caster after striking another body. This
-- fixture tests source selection through the production chain policy while
-- recording impacts so the geometry is independent of the chosen flavour.
local chain = require("policy.combat.monster_area.chain_of_chaos")
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")

local test = {}
local caster = 11
local foe = 22

-- The two actors share an open row. A single cast has enough power for two
-- arcs, which exposes the source's return-to-caster visual exception.
local function context()
    local positions = {
        [caster] = {
            level_id = 1,
            x = 0,
            y = 0,
        },

        [foe] = {
            level_id = 1,
            x = 2,
            y = 0,
        },
    }
    local ctx = {}

    -- Candidate discovery uses live ECS state on every jump.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.HEALTH then
            return { current = 30 }
        end

        if id == component.ACTOR then
            return { kind_id = monsters.MONS_RAT }
        end

        return nil
    end

    -- The source monster iterator sees both actors in stable order.
    function ctx:query()
        return {
            caster,
            foe,
        }
    end

    -- Neither test actor is the player, including on the return arc.
    function ctx:has()
        return false
    end

    -- This topology test does not include a player candidate or messages.
    function ctx:player()
        return nil
    end

    -- There are no solid or actor blockers along either short ray.
    function ctx:visible()
        return true
    end

    -- Clear walls do not hide either candidate from the original caster.
    function ctx:visible_no_trans()
        return true
    end

    -- The target actor itself is allowed at the end of a projectile ray.
    function ctx:projectile_clear()
        return true
    end

    -- Jitter by zero and decline the one-in-ten closer-target exception.
    -- The same draw makes each attenuation nine power points.
    function ctx:random(_, bound)
        return bound > 1 and 1 or 0
    end

    return ctx
end

-- A return arc must remain in the chain but cannot apply a chaos effect
-- to its original caster. Its power is reduced after the first impact.
function test.run()
    local impacts = {}

    chain.resolve(context(), caster, 17, function(_, source, target,
        power, visual)
        impacts[#impacts + 1] = {
            source = source,
            target = target,
            power = power,
            visual = visual,
        }
    end)

    harness.equal(#impacts, 2,
        "seventeen power produces two nine-point-attenuated arcs")
    harness.equal(impacts[1].target, foe,
        "first jump selects the nearest other actor")
    harness.equal(impacts[1].power, 17,
        "first arc uses the starting spell power")
    harness.equal(impacts[2].target, caster,
        "the next jump may return to the original caster")
    harness.equal(impacts[2].power, 8,
        "the second arc uses attenuated power")
    harness.truthy(impacts[2].visual,
        "a return arc is visual rather than a chaos effect")
end

return test
