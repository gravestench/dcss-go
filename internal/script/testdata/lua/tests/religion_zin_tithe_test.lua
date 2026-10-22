-- Zin's gold rule uses the real wallet and floor item schemas. Each case has
-- its own player so worship history and fractional tithe carry cannot leak.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local jobs = require("ids.jobs")
local materialize = require("policy.item_generation.materialize")
local sources = require("constants.religion_sources")
local species = require("ids.species")
local worship = require("policy.religion.worship")

local test = {}

-- A player with a real wallet is enough for the worship and pickup owners.
local function player(ctx, gold)
    local entity = ctx:create()

    ctx:add(entity, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Zin test",
    })
    ctx:add(entity, component.WALLET, {
        gold = gold or 0,
    })
    ctx:add(entity, component.RELIGION_WORSHIP, {})

    return entity
end

-- Materialize gold through production code so item metadata is not copied
-- into the test and a picked-up entity can be destroyed normally.
local function floor_gold(ctx, quantity, x, source, components)
    return materialize.create(ctx, {
        kind_id = item_ids.OBJ_GOLD,
        quantity = quantity,
        plus = 0,
        charges = 0,
        ego = "",
        source = source,
        components = components,
    }, {
        position = {
            level_id = 1,
            x = x,
            y = 1,
        },
    })
end

-- Entry tithe uses the carried balance once; leaving and rejoining does not
-- charge the same money a second time because donations remain saved.
local function entry_tithe(ctx)
    local actor = player(ctx, 1000)

    worship.join(ctx, actor, gods.ZIN, sources.ALTAR)

    local wallet = ctx:get(actor, component.WALLET)

    harness.equal(wallet.gold, 900)
    harness.equal(wallet.donations, 100)
    harness.equal(wallet.tithe_base, 0)

    worship.renounce(ctx, actor)
    worship.join(ctx, actor, gods.ZIN, sources.ALTAR)

    wallet = ctx:get(actor, component.WALLET)

    harness.equal(wallet.gold, 900, "already tithed gold stays intact")
    harness.equal(wallet.donations, 100)
end

-- A pile seen before conversion still pays money but yields no piety. A
-- later pile pays and grants piety; sight status belongs to each item.
local function sight_and_pickup(ctx)
    local zin = require("policy.religion.gods.zin")
    local wallet = require("policy.shops.wallet")
    local actor = player(ctx)
    local old = floor_gold(ctx, 20, 1)

    zin.mark_seen(ctx, actor, old)
    worship.join(ctx, actor, gods.ZIN, sources.ALTAR)

    harness.equal(wallet.pickup(ctx, actor, old), 18)
    harness.equal(ctx:get(actor, component.WALLET).donations, 2)
    harness.equal(ctx:get(actor, component.RELIGION_WORSHIP).piety, 15)

    local new = floor_gold(ctx, 20, 2)

    zin.mark_seen(ctx, actor, new)

    harness.equal(wallet.pickup(ctx, actor, new), 18)
    harness.equal(ctx:get(actor, component.WALLET).gold, 36)
    harness.equal(ctx:get(actor, component.WALLET).donations, 4)
    harness.truthy(ctx:get(actor, component.RELIGION_WORSHIP).piety > 15,
        "gold first seen while worshipping grants Zin piety")
end

-- Fractional carry makes ten one-gold pickups pay the same tithe as one
-- ten-gold pickup, even though the first nine collect no whole gold piece.
local function fractional_piles(ctx)
    local wallet = require("policy.shops.wallet")
    local actor = player(ctx)

    worship.join(ctx, actor, gods.ZIN, sources.ALTAR)

    for count = 1, 10 do
        local pile = floor_gold(ctx, 1, count)

        wallet.pickup(ctx, actor, pile)
    end

    local state = ctx:get(actor, component.WALLET)

    harness.equal(state.gold, 9)
    harness.equal(state.donations, 1)
    harness.equal(state.tithe_base, 0)
end

-- Source stolen gold can be explicitly exempted, and acquirement gold
-- carries its source flag through the normal item materialization path.
local function special_gold(ctx)
    local states = require("constants.zin_tithe_state")
    local purpose = require("constants.item_generation_purpose")
    local wallet = require("policy.shops.wallet")
    local zin = require("policy.religion.gods.zin")
    local actor = player(ctx)

    worship.join(ctx, actor, gods.ZIN, sources.ALTAR)

    local stolen = floor_gold(ctx, 20, 15)

    ctx:add(stolen, component.GOLD_TITHE, {
        state = states.NO_TITHE,
    })

    zin.mark_seen(ctx, actor, stolen)

    harness.equal(wallet.pickup(ctx, actor, stolen), 20)
    harness.equal(ctx:get(actor, component.WALLET).donations, 0)

    local acquired = floor_gold(ctx, 200, 16, {
        purpose = purpose.ACQUIREMENT,
    })
    local metadata = ctx:get(acquired, component.GOLD_TITHE)

    harness.truthy(metadata.acquired)
    zin.mark_seen(ctx, actor, acquired)
    harness.truthy(ctx:get(acquired, component.GOLD_TITHE).acquired)
    harness.equal(wallet.pickup(ctx, actor, acquired), 180)
    harness.equal(ctx:get(actor, component.WALLET).donations, 20)

    -- A mod may attach its own gold state during generation. Acquirement
    -- should add its source fact to that state instead of adding it twice.
    local supplied = floor_gold(ctx, 20, 18, {
        purpose = purpose.ACQUIREMENT,
    }, {
        [component.GOLD_TITHE] = {
            state = states.NO_TITHE,
        },
    })
    local supplied_metadata = ctx:get(supplied, component.GOLD_TITHE)

    harness.equal(supplied_metadata.state, states.NO_TITHE)
    harness.truthy(supplied_metadata.acquired)
end

-- At the piety ceiling Zin does not take money, though fractional carry is
-- still updated so the next pile starts from the same source remainder.
local function maximum_piety(ctx)
    local wallet = require("policy.shops.wallet")
    local actor = player(ctx)

    worship.join(ctx, actor, gods.ZIN, sources.ALTAR)

    local devotion = ctx:get(actor, component.RELIGION_WORSHIP)

    devotion.piety = 200
    ctx:set(actor, component.RELIGION_WORSHIP, devotion)

    local pile = floor_gold(ctx, 19, 17)

    harness.equal(wallet.pickup(ctx, actor, pile), 19)
    harness.equal(ctx:get(actor, component.WALLET).donations, 0)
    harness.equal(ctx:get(actor, component.WALLET).tithe_base, 9)
end

-- Run the complete cash path in one fixture without duplicating schemas.
function test.run(ctx)
    entry_tithe(ctx)
    sight_and_pickup(ctx)
    fractional_piles(ctx)
    special_gold(ctx)
    maximum_piety(ctx)
end

return test
