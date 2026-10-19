-- Cleansing Flame uses production blast geometry, source monster HD, and
-- holy immunity. The fixture replaces only the host grid and unrelated
-- armour, allegiance, health, and visibility services.
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local effect = require("policy.combat.monster_spells.cleansing_flame")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local test = {}
local caster = 11
local enemy = 22
local ally = 33

-- Place a holy caster between one enemy and one ally so the source tracer
-- must reject the equal collateral case before accepting the safe case.
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
        [enemy] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_RAT,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 3,
                y = 2,
            },
            [component.HEALTH] = { current = 10 },
        },
        [ally] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_GOBLIN,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 1,
                y = 2,
            },
            [component.HEALTH] = { current = 10 },
        },
    }
    local ctx = {}

    -- Read current actor and status components as the blast visits cells.
    function ctx:get(entity, id)
        return state[entity] and state[entity][id]
    end

    -- No player stands in this monster-on-monster area test.
    function ctx:player()
        return nil
    end

    -- The source decision checks for a player before reading progression.
    function ctx:has(entity, id)
        return state[entity] and state[entity][id] ~= nil or false
    end

    -- A floor-only grid lets the real source blast propagation run.
    function ctx:cell(_, x, y)
        if x >= 0 and x < 5 and y >= 0 and y < 5 then
            return terrain.DNGN_FLOOR
        end

        return nil
    end

    -- The fixture has no wall that would shield the enemy or ally.
    function ctx:walkable(level_id, x, y)
        return self:cell(level_id, x, y) ~= nil
    end

    -- Occupancy changes when the ally leaves the blast before resolution.
    function ctx:actor_at(level_id, x, y)
        for _, entity in ipairs({ caster, enemy, ally }) do
            local position = state[entity][component.POSITION]

            if position and position.level_id == level_id and
                position.x == x and position.y == y then
                return entity
            end
        end

        return nil
    end

    -- Minimum deterministic rolls expose the exact two-die source floor.
    function ctx:random(_, bound)
        harness.truthy(bound > 0, "the source roll has a valid bound")

        return 0
    end

    -- Hidden cast messages have no effect on the target or damage checks.
    function ctx:emit()
    end

    return ctx, state
end

-- Restore cached Lua policy tables after the fixture to avoid test drift.
local function restore(old)
    targets.enemy = old.enemy
    senses.player_sees_actor = old.sees
    direct.armour = old.armour
    direct.damage = old.damage
end

-- Check ally avoidance, saved self target, source damage, and holy caster
-- immunity using the real effect and blast geometry.
function test.run()
    local old = {
        enemy = targets.enemy,
        sees = senses.player_sees_actor,
        armour = direct.armour,
        damage = direct.damage,
    }
    local hits = {}

    -- The fixture's rat is hostile; both angel and goblin are allies.
    targets.enemy = function(_, _, target)
        return target == enemy
    end

    -- Hide narration so it cannot demand presentation-only host services.
    senses.player_sees_actor = function()
        return false
    end

    -- The minimum-damage test fixes unrelated AC at zero.
    direct.armour = function(_, _, raw)
        return raw
    end

    -- Record the spell's attributed HP impact after holy adjustment.
    direct.damage = function(_, _, target, amount)
        hits[#hits + 1] = {
            target = target,
            amount = amount,
        }
    end

    local ctx, state = context()

    harness.falsy(effect.plan(ctx, caster),
        "equal ally and enemy impact fails the 80 percent foe ratio")

    state[ally][component.POSITION] = nil

    local plan = effect.plan(ctx, caster)

    harness.truthy(plan,
        "one enemy without allied collateral permits cleansing flame")
    effect.resolve(ctx, caster, enemy, nil, plan)
    harness.equal(#hits, 1,
        "the immune holy caster takes no blast damage")
    harness.equal(hits[1].target, enemy,
        "the hostile actor receives the blast")
    harness.equal(hits[1].amount, 2,
        "minimum source rolls deal two raw holy damage")

    restore(old)
end

return test
