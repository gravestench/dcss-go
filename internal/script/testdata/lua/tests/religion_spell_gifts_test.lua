-- Divine spell gifts use the production spell catalog and ECS records.
-- Permanent Kiku knowledge and temporary Vehumet offers must never share
-- a second, test-only spell library or depend on content file load order.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gifts = require("policy.religion.gifts")
local gods = require("constants.gods")
local harness = require("tests.harness")
local input_spells = require("policy.input.spells")
local jobs = require("ids.jobs")
local learning = require("policy.character.spell_learning")
local piety = require("policy.religion.piety")
local records = require("policy.character.spell_records")
local species = require("ids.species")
local sources = require("constants.religion_sources")
local spell_ids = require("ids.spells")
local worship = require("policy.religion.worship")

local test = {}

-- The wrapper changes only the player lookup, leaving ECS access and random
-- draws on the real VM. God gifts can then read actual skills and origin.
local function owner(ctx, god_id, points, level)
    local entity = ctx:create()
    local game = setmetatable({}, { __index = ctx })

    function game:player()
        return entity
    end

    -- The standalone Lua harness has no game clock; this proxy fixes a
    -- single action boundary without changing the production context API.
    function game:aut()
        return 0
    end

    ctx:add(entity, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Gift test",
    })
    ctx:add(entity, component.PROGRESSION, {
        level = level or 3,
    })
    ctx:add(entity, component.SKILLS, {
        entries = {},
    })
    ctx:add(entity, component.SPELLCASTING, {})
    ctx:add(entity, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = points,
    })

    return game, entity
end

-- Kiku's first star gives Necrotise and three different source spells.
-- The third star adds a distinct five-spell set to the same ECS library.
local function kiku_sets(ctx)
    local game, player = owner(ctx, gods.KIKUBAAQUDGHA, 29)

    piety.gain(game, player, 1, 1, false)

    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local early = records.list(game, player)

    harness.equal(state.gift_total[gods.KIKUBAAQUDGHA], 1)
    harness.equal(#early, 4)
    harness.truthy(records.find(game, player,
        spell_ids.SPELL_NECROTISE).state.in_library)

    for _, entry in ipairs(early) do
        harness.truthy(entry.state.in_library)
        harness.equal(entry.state.known_slot, 0)
        harness.equal(catalog.get(categories.SPELLS,
            entry.state.spell_id).status, "defined")
    end

    piety.gain(game, player, 45, 1, false)

    state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.gift_total[gods.KIKUBAAQUDGHA], 2)
    harness.equal(#records.list(game, player), 9)

    piety.gain(game, player, 1, 1, false)

    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_total[gods.KIKUBAAQUDGHA], 2)
end

-- Vehumet offers a level-one source book spell at the first star. The
-- offer is visible to memorisation without becoming permanent library data.
local function vehumet_offer(ctx)
    local game, player = owner(ctx, gods.VEHUMET, 29)

    piety.gain(game, player, 1, 1, false)

    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local offer = ctx:get(player, component.RELIGION_VEHUMET)
    local spell_id = offer.offer_ids[1]
    local spell = catalog.get(categories.SPELLS, spell_id)

    harness.equal(state.gift_total[gods.VEHUMET], 1)
    harness.equal(#offer.offer_ids, 1)
    harness.equal(spell.level, 1)
    harness.truthy(offer.old_ids[spell_id])
    harness.truthy(offer.cooldown_end_aut > game:aut())
    local offered_record = records.find(game, player, spell_id)

    harness.truthy(offered_record)
    harness.falsy(offered_record.state.in_library)
    harness.equal(offered_record.state.offered_by, gods.VEHUMET)
    harness.equal(#input_spells.choices({
        mode = "spell_memorise",
        spells = {
            {
                id = spell_id,
                offered = true,
                known_slot = 0,
            },
        },
    }), 1)

    local ordered = input_spells.choices({
        mode = "spell_memorise",
        spells = {
            {
                id = spell_ids.SPELL_MAGIC_DART,
                in_library = true,
                offered = false,
                known_slot = 0,
            },
            {
                id = spell_ids.SPELL_SHATTER,
                offered = true,
                known_slot = 0,
            },
        },
    })

    harness.equal(ordered[1].id, spell_ids.SPELL_SHATTER)

    local started = learning.begin(game, player, spell_id)

    harness.truthy(started.started)
    learning.advance(game, player, { kind = 6 })

    offer = ctx:get(player, component.RELIGION_VEHUMET)

    harness.equal(#offer.offer_ids, 0)
    harness.equal(offer.cooldown_end_aut, 0)
    harness.truthy(records.find(game, player, spell_id).state.known_slot > 0)
    harness.truthy(records.find(game, player, spell_id).state.in_library)
    harness.equal(records.find(game, player, spell_id)
        .state.offered_by, "")

    return spell_id
end

-- Leaving Vehumet removes temporary access but retains previous-offer
-- history so a later visit prefers genuinely new spells.
local function vehumet_departure(ctx)
    local game, player = owner(ctx, gods.VEHUMET, 29)

    piety.gain(game, player, 1, 1, false)

    local offered = ctx:get(player, component.RELIGION_VEHUMET)
        .offer_ids[1]

    harness.truthy(learning.begin(game, player, offered).started)

    worship.renounce(game, player)

    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local offer = ctx:get(player, component.RELIGION_VEHUMET)

    harness.equal(state.gift_current[gods.VEHUMET], 0)
    harness.equal(state.gift_total[gods.VEHUMET], 1)
    harness.equal(#offer.offer_ids, 0)
    harness.truthy(offer.old_ids[offered])
    harness.falsy(gifts.offering(game, player, offered))
    harness.equal(records.find(game, player, offered)
        .state.offered_by, "")
    harness.equal(ctx:get(player, component.SPELLCASTING)
        .learning_remaining, 0)

    worship.join(game, player, gods.VEHUMET, sources.ALTAR)

    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_total[gods.VEHUMET], 1)
end

-- Once the source replacement cooldown ends, a later eligible window
-- withdraws an unaccepted offer and prefers a spell never offered before.
local function vehumet_replacement(ctx)
    local game, player = owner(ctx, gods.VEHUMET, 29, 3)

    piety.gain(game, player, 1, 1, false)

    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local offer = ctx:get(player, component.RELIGION_VEHUMET)
    local first = offer.offer_ids[1]

    state.piety = 90
    ctx:set(player, component.RELIGION_WORSHIP, state)
    offer.cooldown_end_aut = 0
    ctx:set(player, component.RELIGION_VEHUMET, offer)

    piety.gain(game, player, 1, 1, false)

    offer = ctx:get(player, component.RELIGION_VEHUMET)

    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_total[gods.VEHUMET], 2)
    harness.equal(#offer.offer_ids, 1)
    harness.truthy(offer.offer_ids[1] ~= first)
    harness.equal(records.find(game, player, first).state.offered_by, "")
    harness.equal(records.find(game, player, offer.offer_ids[1])
        .state.offered_by, gods.VEHUMET)
end

-- Check both gift paths through piety and one through the memorisation
-- completion boundary; validation uses these same component schemas.
function test.run(ctx)
    kiku_sets(ctx)
    vehumet_offer(ctx)
    vehumet_departure(ctx)
    vehumet_replacement(ctx)
end

return test
