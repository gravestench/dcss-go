-- Source direct explosions choose a visible cell even when a clear wall
-- or another actor breaks an ordinary projectile path. The blast then
-- begins at that selected cell rather than the first ray contact.
local blast = require("policy.combat.monster_beams.explosion")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local effect = require("policy.combat.monster_spells.call_down_damnation")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")
local trajectory = require("policy.combat.trajectory")

local test = {}
local caster = 11
local foe = 22

-- A clear but solid wall separates the caster from a visible rat. The
-- radius-one target cell itself remains open and occupied by the rat.
local function context()
    local state = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_ANGEL,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 2,
            },
            [component.HEALTH] = { current = 40 },
        },
        [foe] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_RAT,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 4,
                y = 2,
            },
            [component.HEALTH] = { current = 10 },
        },
    }
    local ctx = {}

    -- Power and source-style collateral scoring read production profiles.
    function ctx:get(entity, id)
        return state[entity] and state[entity][id]
    end

    -- No player-specific HD adjustment is needed for this rat victim.
    function ctx:has(entity, id)
        return state[entity] and state[entity][id] ~= nil or false
    end

    -- The spell target remains visible through transparent solid terrain.
    function ctx:visible()
        return true
    end

    -- The old indirect ray would reject this blocked path if asked.
    function ctx:visible_no_trans()
        return false
    end

    -- One clear wall lies between the two actor positions.
    function ctx:cell(_, x, y)
        if x == 3 and y == 2 then
            return terrain.DNGN_CLEAR_ROCK_WALL
        end

        if x >= 0 and x < 7 and y >= 0 and y < 7 then
            return terrain.DNGN_FLOOR
        end

        return nil
    end

    -- Solid wall cells stop blast propagation from the target cell.
    function ctx:walkable(level_id, x, y)
        return self:cell(level_id, x, y) == terrain.DNGN_FLOOR
    end

    -- The foe, not the wall or an intervening actor, occupies the blast.
    function ctx:actor_at(_, x, y)
        return x == 4 and y == 2 and foe or nil
    end

    return ctx
end

-- Restore patched cached modules so later tests use production behavior.
local function restore(old)
    targets.enemy = old.enemy
    blast.resolve = old.blast
    trajectory.to_target = old.trace
end

-- The production plan and resolution must keep the target cell despite
-- transparent but solid intervening terrain.
function test.run()
    local old = {
        enemy = targets.enemy,
        blast = blast.resolve,
        trace = trajectory.to_target,
    }
    local ctx = context()
    local reached

    -- Only the rat is hostile; the caster cannot count as an enemy.
    targets.enemy = function(_, _, actor)
        return actor == foe
    end

    -- A direct explosion must never trace the ordinary projectile ray.
    trajectory.to_target = function()
        error("direct explosion traced through the wall")
    end

    -- Capture the blast origin while leaving plan and beam resolution real.
    blast.resolve = function(_, _, profile, trace, destination)
        reached = {
            id = profile.id,
            x = destination.x,
            y = destination.y,
            contacts = #trace.contacts,
        }
    end

    local profile = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_CALL_DOWN_DAMNATION)

    harness.truthy(profile.direct_explosion,
        "the source zap is marked as placeable without a clear ray")

    local plan = effect.plan(ctx, caster, foe)

    harness.truthy(plan,
        "a foe behind a visible clear wall can be targeted")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.equal(reached.x, 4,
        "the blast starts at the foe's selected cell")
    harness.equal(reached.contacts, 0,
        "no earlier actor can intercept a direct explosion")

    restore(old)
end

return test
