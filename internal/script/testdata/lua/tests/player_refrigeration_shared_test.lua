-- The player spell imports the same source die and adjacency owner used by
-- the new monster cast. Verify that its command entry still damages a
-- visible monster after that shared-rule extraction.
local component = require("constants.component")
local damage = require("policy.magic.damage")
local defense = require("policy.combat.monster_defense")
local effect = require("policy.magic.effects.zaps.refrigeration")
local harness = require("tests.harness")
local monsters = require("ids.monsters")

local test = {}
local player = 11
local rat = 22

-- Keep the production content catalog and shared refrigeration formula;
-- only the ECS and sight host methods need a small local game fixture.
local function context()
    local state = {
        [player] = {
            [component.ACTOR] = {},
            [component.PLAYER] = {},
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 2,
            },
            [component.HEALTH] = { current = 20 },
        },
        [rat] = {
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
    }
    local ctx = {}

    -- The player rule reads the same components as the monster rule.
    function ctx:get(entity, id)
        return state[entity] and state[entity][id]
    end

    -- The source adjacency snapshot distinguishes player from monster.
    function ctx:player()
        return player
    end

    -- Query both bodies so the caster dilutes the adjacent rat's dice.
    function ctx:query()
        return { player, rat }
    end

    -- Open LOS_NO_TRANS is the source spell's actual targeting geometry.
    function ctx:visible_no_trans()
        return true
    end

    -- Minimum source rolls expose the four-die damage floor.
    function ctx:random(_, bound)
        harness.truthy(bound > 0, "a spell roll has a positive bound")

        return 0
    end

    -- Presentation messages should not affect damage assertions.
    function ctx:emit()
    end

    return ctx
end

-- Restore cached production functions for the following Lua tests.
local function restore(old)
    defense.armour = old.armour
    damage.apply = old.apply
end

-- Call the actual player resolver and observe its cold damage after the
-- shared source dice, adjacency reduction, and resistance calculation.
function test.run()
    local old = {
        armour = defense.armour,
        apply = damage.apply,
    }
    local hits = {}

    -- Fix independent monster armour at zero for this source-dice check.
    defense.armour = function()
        return 0
    end

    -- Record the damage amount where the production health owner begins.
    damage.apply = function(_, target, amount)
        hits[#hits + 1] = {
            target = target,
            amount = amount,
        }

        return 1
    end

    effect.resolve(context(), player, nil, nil, 0)
    harness.equal(#hits, 1,
        "the player cast still reaches the nearby monster")
    harness.equal(hits[1].target, rat,
        "the shared area rule never hits its own caster")
    harness.equal(hits[1].amount, 4,
        "four minimum cold dice survive the shared-rule extraction")

    restore(old)
end

return test
