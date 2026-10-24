-- Xom's weapon animation transfers a hostile's actual item into a saved
-- friendly dancing weapon. No copy may lose its artefact or enchantment.
local artefact_kinds = require("constants.artefact_kinds")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local events = require("policy.religion.xom.events")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local good = require("policy.religion.xom.selection_good")
local items = require("ids.items")
local monsters = require("ids.monsters")
local slots = require("constants.monster_equipment_slots")
local streams = require("constants.rng_streams")

local test = {}

-- The source tries this gate after group allies. Force the earlier gates
-- to fail and check the exact draws before the shared candidate scan.
local function animation_gate(owner, player)
    local bounds = {
        3, 100, 100, 100, 100, 5, 5, 100, 8,
        100, 10, 8, 100,
    }
    local draws = 0

    -- Mismatched draws fail at their own source boundary.
    function owner:random(stream, bound)
        draws = draws + 1

        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, bounds[draws])

        return draws >= 12 and 0 or bound - 1
    end

    harness.equal(good.choose(owner, player, 100, 2,
        streams.RELIGION), ids.GOOD_ANIMATE_MON_WPN)
    harness.equal(draws, #bounds)
end

-- Build a real carried and equipped item so the effect must move its
-- existing entity rather than manufacture a replacement weapon.
local function equip(ctx, monster, kind_id)
    local weapon = ctx:create()

    ctx:add(weapon, component.ITEM, {
        kind_id = kind_id,
        quantity = 1,
        plus = 3,
        ego = "",
        charges = 0,
    })
    ctx:add(weapon, component.CARRIED_BY, {
        holder = monster,
    })
    ctx:add(weapon, component.EQUIPPED, {
        slot = slots.WEAPON,
    })

    return weapon
end

-- The source excludes an irreplaceable unique weapon before choosing a
-- candidate. The ordinary club remains eligible and keeps its entity ID.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local target = fixture.actor(ctx, monsters.MONS_GNOLL, 9, 7, 12)
    local weapon = equip(ctx, target, items.WPN_CLUB)
    local unique_owner = fixture.actor(ctx,
        monsters.MONS_GNOLL, 10, 7, 12)
    local unique = equip(ctx, unique_owner, items.WPN_CLUB)

    ctx:add(unique, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.UNIQUE,
        unique_id = "xom_test_unique",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    animation_gate(owner, player)

    -- The Xom choice and summon position are stable; ordinary summon HP
    -- can still use its own registered stream.
    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return 0
        end

        return ctx:random(stream, bound)
    end

    -- The temporary starting loadout uses the current Dungeon depth.
    function owner:level_depth()
        return 1
    end

    local dancer = events.apply(owner, player,
        ids.GOOD_ANIMATE_MON_WPN, 20, {
            stream = streams.RELIGION,
        })

    harness.truthy(dancer)
    harness.equal(ctx:get(dancer, component.ACTOR).kind_id,
        monsters.MONS_DANCING_WEAPON)
    harness.equal(ctx:get(dancer, component.SUMMON).source_id,
        gods.XOM)
    harness.equal(ctx:get(weapon, component.CARRIED_BY).holder,
        dancer)
    harness.truthy(ctx:has(dancer, constructs.DANCING_WEAPON))
    harness.equal(ctx:get(weapon, component.ITEM).plus, 3)
    harness.equal(ctx:get(unique, component.CARRIED_BY).holder,
        unique_owner)
end

return test
