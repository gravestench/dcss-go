-- A light-flavoured Chaos arc uses the same blindness and confusion owners
-- as other light effects. This tests both actor kinds after beam contact.
local component = require("constants.component")
local confusion = require("policy.magic.player_confusion")
local enchant = require("policy.combat.monster_enchant")
local harness = require("tests.harness")
local light = require("policy.combat.monster_area.chaos_light")
local monsters = require("ids.monsters")

local test = {}
local player = 11
local monster = 22

-- An accepted one-in-three player roll gives two turns of confusion. The
-- monster's source HD scaling stays inside the production blind owner.
function test.run()
    local old_confusion = confusion.extend
    local old_blind = enchant.blind
    local observed = {}
    local ctx = {}

    -- Player identity chooses confusion instead of monster blindness.
    function ctx:has(target, id)
        return target == player and id == component.PLAYER
    end

    -- Monster blindness needs its registered kind, not a test schema.
    function ctx:get(target, id)
        if target == monster and id == component.ACTOR then
            return { kind_id = monsters.MONS_RAT }
        end

        return nil
    end

    -- Force the source one-in-three confusion branch and record its rolls.
    function ctx:random(_, bound)
        observed[#observed + 1] = bound

        return 0
    end

    confusion.extend = function(_, target, turns)
        observed.player = {
            target = target,
            turns = turns,
        }
    end

    enchant.blind = function(_, target, definition)
        observed.monster = {
            target = target,
            definition = definition,
        }
    end

    light.after_hit(ctx, monster, player)
    light.after_hit(ctx, player, monster)

    harness.equal(observed.player.target, player,
        "the player receives light confusion")
    harness.equal(observed.player.turns, 2,
        "the source player duration begins at two turns")
    harness.equal(observed.monster.target, monster,
        "the monster receives blindness")
    harness.equal(observed.monster.definition.id,
        monsters.MONS_RAT,
        "blindness uses the monster's real catalog definition")
    harness.equal(observed[1], 3,
        "player confusion has a one-in-three chance")
    harness.equal(observed[2], 2,
        "successful confusion adds zero or one turn")

    confusion.extend = old_confusion
    enchant.blind = old_blind
end

return test
