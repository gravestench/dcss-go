-- The production area query shares geometry across self-centered spells
-- but leaves allegiance and resistance to each spell. This small grid
-- fixture supplies only ECS and map services used by that query.
local actors = require("policy.combat.monster_area.actors")
local component = require("constants.component")
local harness = require("tests.harness")
local terrain = require("constants.terrain")

local test = {}
local caster = 11
local ally = 22
local foe = 33
local dead = 44

-- Keep all bodies in the component query; the policy must filter the
-- caster, corpse, and cells blocked by a transparent wall itself.
local function context()
    local state = {
        [caster] = {
            [component.ACTOR] = {},
            [component.POSITION] = {
                level_id = 1,
                x = 1,
                y = 1,
            },
            [component.HEALTH] = { current = 10 },
        },
        [ally] = {
            [component.ACTOR] = {},
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 1,
            },
            [component.HEALTH] = { current = 10 },
        },
        [foe] = {
            [component.ACTOR] = {},
            [component.POSITION] = {
                level_id = 1,
                x = 3,
                y = 1,
            },
            [component.HEALTH] = { current = 10 },
        },
        [dead] = {
            [component.ACTOR] = {},
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 2,
            },
            [component.HEALTH] = { current = 0 },
        },
    }
    local ctx = {}

    -- The policy reads current components, not a frozen cast-time list.
    function ctx:get(entity, id)
        return state[entity] and state[entity][id]
    end

    -- Akara supplies matching handles in stable order to every area rule.
    function ctx:query()
        return { caster, ally, foe, dead }
    end

    -- A clear wall may hide a body from a LOS_NO_TRANS area spell.
    function ctx:visible_no_trans(_, _, _, _, x)
        return x ~= 3
    end

    -- Blast propagation needs only the fixed floor cells in this fixture.
    function ctx:cell(_, x, y)
        if x >= 0 and x < 5 and y >= 0 and y < 5 then
            return terrain.DNGN_FLOOR
        end

        return nil
    end

    -- No wall blocks the one-cell explosion around its chosen center.
    function ctx:walkable(level_id, x, y)
        return self:cell(level_id, x, y) ~= nil
    end

    -- Occupancy is read at resolution, after any movement since planning.
    function ctx:actor_at(level_id, x, y)
        for _, entity in ipairs({ caster, ally, foe, dead }) do
            local position = state[entity][component.POSITION]

            if position.level_id == level_id and
                position.x == x and position.y == y then
                return entity
            end
        end

        return nil
    end

    return ctx, state
end

-- Include a friendly living actor in both shapes, reject a dead actor,
-- and let the two geometry rules differ on a wall-hidden foe.
function test.run()
    local ctx, state = context()
    local nearby = actors.los(ctx, caster, 3)

    harness.equal(#nearby, 1,
        "LOS_NO_TRANS includes only the visible live ally")
    harness.equal(nearby[1], ally,
        "geometry leaves allegiance to the spell")

    local blast = actors.blast(ctx, 1, 2, 1, 1)

    harness.equal(#blast, 3,
        "a blast includes its living center and adjacent actors")
    harness.equal(blast[1], ally,
        "the center occupant is returned before the ring")

    state[foe][component.POSITION].x = 4

    local after_move = actors.blast(ctx, 1, 2, 1, 1)

    harness.equal(#after_move, 2,
        "resolution reads moved actors from the current grid")
end

return test
