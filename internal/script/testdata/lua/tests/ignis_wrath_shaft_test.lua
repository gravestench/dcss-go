-- Ignis's first wrath branch must request a real fall when the Dungeon
-- has another floor. The request belongs to the player ECS actor.
local branches = require("ids.branches")
local artefacts = require("ids.artefacts")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local ignis = require("policy.religion.wrath.ignis")
local monsters = require("ids.monsters")
local items = require("ids.items")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local shaft = require("policy.world.shaft")
local terrain = require("constants.terrain")

local test = {}

-- D:1 can fall to D:2. Both wrath and destination rolls choose their
-- first outcome, so no generated map or second branch is involved here.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        40, 10, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local owner = setmetatable({}, {
        __index = fixture.context(ctx, player),
    })

    function owner:level_branch(_)
        return branches.BRANCH_DUNGEON
    end

    function owner:level_depth(_)
        return 1
    end

    function owner:random(stream, _)
        harness.equal(stream, streams.CARDS)

        return 0
    end

    harness.truthy(ignis.apply(owner, player))

    local pending = ctx:get(player, component.PENDING_SHAFT)

    harness.truthy(pending, "Ignis did not request a shaft")
    harness.equal(pending.branch_id, branches.BRANCH_DUNGEON)
    harness.equal(pending.local_depth, 2)

    -- Stairs have a dry floor but cannot become shafts. The branch bottom
    -- also rejects the effect without spending the destination draw.
    owner.cells["40:10"] = terrain.DNGN_STONE_STAIRS_DOWN_I
    harness.falsy(shaft.destination(owner, player, streams.CARDS))
    owner.cells["40:10"] = terrain.DNGN_FLOOR

    function owner:level_depth(_)
        return 15
    end

    harness.falsy(shaft.destination(owner, player, streams.CARDS))

    -- At D:3 all three outcomes are possible; the largest fall reaches
    -- D:6, while the source branch bottom still caps later floors.
    function owner:level_depth(_)
        return 3
    end

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        harness.equal(bound, 3)

        return 2
    end

    harness.equal(shaft.destination(owner, player,
        streams.CARDS).local_depth, 6)

    -- Abyss forbids ordinary cross-level travel, which is the source
    -- connectivity test for shafts even when its depth catalog has room.
    function owner:level_branch(_)
        return branches.BRANCH_ABYSS
    end

    harness.falsy(shaft.destination(owner, player, streams.CARDS))

    function owner:level_branch(_)
        return branches.BRANCH_DUNGEON
    end

    -- A worn pair of Mountain Boots consumes the shaft choice but keeps
    -- the player on this floor. The resistance is the ordinary gear rule.
    local boots = ctx:create()

    ctx:add(boots, component.ITEM, {
        kind_id = items.ARM_BOOTS,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(boots, component.CARRIED_BY, {
        holder = player,
    })
    ctx:add(boots, component.EQUIPPED, {
        slot = "boots",
    })
    ctx:add(boots, component.ITEM_ARTEFACT, {
        unique_id = artefacts.UNRAND_MOUNTAIN_BOOTS,
    })

    ctx:remove(player, component.PENDING_SHAFT)

    function owner:level_depth(_)
        return 1
    end

    function owner:random(stream, _)
        harness.equal(stream, streams.CARDS)

        return 0
    end

    harness.truthy(shaft.ignis(owner, player, streams.CARDS))
    harness.falsy(ctx:get(player, component.PENDING_SHAFT))

    -- A shaft landing cannot be deep water or occupied by a monster.
    -- The safe third draw is far enough from that hostile body.
    fixture.actor(ctx, monsters.MONS_ORC, 2, 2, 10)
    owner.cells["0:0"] = terrain.DNGN_DEEP_WATER

    function owner:level_size(_)
        return 12, 12
    end

    function owner:records_at(_, _, _)
        return {}
    end

    local coordinates = {
        0, 0,
        2, 2,
        10, 10,
    }
    local next_draw = 0

    function owner:random(stream, bound)
        harness.equal(stream, streams.TRAPS)
        harness.equal(bound, 12)
        next_draw = next_draw + 1

        return coordinates[next_draw]
    end

    local landing = shaft.landing(owner, {
        level_id = 1,
    })

    harness.equal(landing.x, 10)
    harness.equal(landing.y, 10)
end

return test
