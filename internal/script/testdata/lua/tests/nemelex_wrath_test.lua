-- Wrath selection and implemented punishments run against saved worship and
-- player resource schemas, so a rejected god never silently spends penance.
local component = require("constants.component")
local attitudes = require("constants.attitude")
local beogh = require("policy.religion.wrath.beogh")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local makhleb = require("policy.religion.wrath.makhleb")
local monsters = require("ids.monsters")
local okawaru = require("policy.religion.wrath.okawaru")
local pool = require("policy.population.pool")
local retribution = require("policy.religion.wrath.retribution")
local roster = require("policy.religion.wrath.roster")
local sif_muna = require("policy.religion.wrath.sif_muna")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local weapon_brands = require("constants.weapon_brands")
local requests = require("constants.vault_monster_requests")
local wrath_card = require("policy.religion.cards.effects.wrath")
local zap_ids = require("policy.magic.effects.zaps.ids")

local test = {}
local summon_context

-- Each fixture draw belongs to the card stream and must fit its source
-- bound. A bound of one still goes through this proxy for call visibility.
local function with_draws(ctx, draws)
    local owner = setmetatable({}, { __index = ctx })
    local used = 0

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        used = used + 1
        local value = draws[used]

        harness.truthy(value ~= nil, "missing wrath draw")
        harness.truthy(value >= 0 and value < bound,
            "invalid wrath draw bound")

        return value
    end

    function owner:draws_used()
        return used
    end

    return owner
end

-- Build a real worship record; the schema supplies every other field and
-- tests observe saved penance through the same component as gameplay.
local function worshipper(ctx, god_id, penance)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = god_id,
        penance = penance or {},
    })

    return player
end

-- The source samples all 26 enum gods, including declined outcomes.
-- Vehumet's god-avatar spell still raises at its sampled god.
local function selection(ctx)
    harness.equal(#roster, 26)
    harness.equal(roster[1], gods.ZIN)
    harness.equal(roster[11], gods.NEMELEX_XOBEH)
    harness.equal(roster[26], gods.IGNIS)

    local player = worshipper(ctx, gods.NO_GOD)
    local owner = with_draws(ctx, { 10, 5 })
    local success, message = pcall(retribution.sample, owner, player)

    harness.falsy(success)
    harness.truthy(string.find(message, "Vehumet god-avatar", 1,
        true))
    harness.equal(owner:draws_used(), 2)
end

-- A hundred real source-declined Ashenzari draws spend the card and emit
-- decks.cc's escape text. Unsupported eligible gods take a separate path.
local function escaped_card(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = setmetatable({}, { __index = ctx })
    local draws = 0
    local message

    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        harness.equal(bound, 26)
        draws = draws + 1

        return 17
    end

    function owner:emit(_, text)
        message = text
    end

    wrath_card.apply(owner, player)

    harness.equal(draws, 100)
    harness.equal(message,
        "You somehow manage to escape divine attention...")
end

-- random_god rejects dead Ignis inside a single outer card attempt.
-- Worship history and cleared penance are the saved source death rule.
local function dead_ignis(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = with_draws(ctx, { 25, 5 })

    ctx:set(player, component.RELIGION_WORSHIP, {
        god_id = gods.NO_GOD,
        worshipped = {
            [gods.IGNIS] = 1,
        },
        penance = {},
    })

    local success, message = pcall(retribution.sample, owner, player)

    harness.falsy(success)
    harness.truthy(string.find(message, "Vehumet god-avatar", 1,
        true))
    harness.equal(owner:draws_used(), 2)
end

-- Good gods spare their own followers and non-hated Nemelex followers.
-- A rejected call leaves penance intact without invoking an effect.
local function eligibility(ctx)
    local player = worshipper(ctx, gods.ZIN, {
        [gods.ZIN] = 5,
    })

    harness.falsy(retribution.invoke_god(ctx, player, gods.ZIN))
    harness.equal(ctx:get(player,
        component.RELIGION_WORSHIP).penance[gods.ZIN], 5)

    ctx:set(player, component.RELIGION_WORSHIP, {
        god_id = gods.NEMELEX_XOBEH,
        penance = {
            [gods.ZIN] = 5,
        },
    })

    harness.falsy(retribution.invoke_god(ctx, player, gods.ZIN))
    harness.falsy(retribution.invoke_god(ctx, player, gods.RU))
    harness.falsy(retribution.invoke_god(ctx, player, gods.ELYVILON))

    -- These source switch entries decline even when hatred permits wrath.
    for _, id in ipairs({
        gods.ASHENZARI,
        gods.GOZAG,
        gods.HEPLIAKLQANA,
    }) do
        harness.falsy(retribution.invoke_god(ctx, player, id))
    end

    ctx:set(player, component.RELIGION_WORSHIP, {
        god_id = gods.MAKHLEB,
    })
    harness.falsy(retribution.invoke_god(ctx, player, gods.ELYVILON))
end

-- Sif's MP branch drains actual saved magic, then the no-bonus route
-- leaves her penance unchanged as divine_retribution specifies.
local function sif_magic(ctx)
    local player = worshipper(ctx, gods.NO_GOD, {
        [gods.SIF_MUNA] = 8,
    })
    local owner = with_draws(ctx, { 6 })

    ctx:add(player, component.MAGIC, {
        current = 9,
        max = 9,
    })

    harness.truthy(retribution.invoke_god(owner, player,
        gods.SIF_MUNA, { no_bonus = true }))
    harness.equal(ctx:get(player, component.MAGIC).current, 0)
    harness.equal(ctx:get(player,
        component.RELIGION_WORSHIP).penance[gods.SIF_MUNA], 8)
    harness.equal(owner:draws_used(), 1)
end

-- The Intelligence branch uses the derived current stat and records a real
-- temporary drain, including its normal XP recovery countdown.
local function sif_intelligence(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = summon_context(ctx, player, { 0, 0 })

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 15,
        dexterity = 10,
    })

    sif_muna.apply(owner, player)

    harness.equal(ctx:get(player,
        component.STAT_LOSS).intelligence, 1)
    harness.equal(owner:draws_used(), 2)
end

-- Confusion uses its saved timer; the separate debuff slot is explicit
-- because the available potion owner would also remove contamination.
local function sif_statuses(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local confusion_owner = with_draws(ctx, { 3, 0 })

    sif_muna.apply(confusion_owner, player)

    harness.equal(ctx:get(player,
        zap_ids.component.PLAYER_CONFUSION).remaining_aut, 50)

    local debuff_owner = with_draws(ctx, { 9 })
    local success, message = pcall(sif_muna.apply,
        debuff_owner, player)

    harness.falsy(success)
    harness.truthy(string.find(message,
        "unimplemented Sif Muna debuff_player wrath", 1, true))
end

-- Use the normal summon placement fixture, with fixed card draws and all
-- unrelated source streams delegated to the production test context.
summon_context = function(ctx, player, draws)
    local owner = fixture.context(ctx, player)
    local used = 0

    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return ctx:random(stream, bound)
        end

        used = used + 1
        local value = draws[used]

        harness.truthy(value ~= nil, "missing summon wrath draw")
        harness.truthy(value < bound, "invalid summon wrath bound")

        return value
    end

    function owner:draws_used()
        return used
    end

    return owner
end

-- Beogh's third branch makes a permanent hostile dancing weapon with its
-- source item attached; equipment survives in the actual item schema.
local function beogh_weapon(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = summon_context(ctx, player, {
        2, 0, 0, 0, 0,
    })

    ctx:add(player, component.PROGRESSION, { level = 5 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })

    beogh.apply(owner, player)

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned, 1)
    harness.equal(ctx:get(summoned[1], component.ACTOR).kind_id,
        monsters.MONS_DANCING_WEAPON)
    harness.equal(ctx:get(summoned[1], component.SUMMON).source_id,
        gods.BEOGH)
    harness.equal(ctx:get(summoned[1], component.SUMMON).attitude,
        attitudes.HOSTILE)
    harness.equal(ctx:get(summoned[1], component.SUMMON).expires_aut, 0)

    local carried = ctx:query({ component.CARRIED_BY })
    local weapon = ctx:get(carried[1], component.ITEM)

    harness.equal(weapon.kind_id, items.WPN_CLUB)
    harness.equal(weapon.ego, weapon_brands.ELECTROCUTION)
    harness.equal(owner:draws_used(), 5)
end

-- Beogh's first branch deals its exact minimum 10 divine HP loss at XL1;
-- all six damage draws use cards and the saved health owner handles impact.
local function beogh_smite(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = summon_context(ctx, player, {
        0, 0, 0, 0, 0, 0, 0,
    })

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.PROGRESSION, { level = 1 })
    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })

    beogh.apply(owner, player)

    harness.equal(ctx:get(player, component.HEALTH).current, 90)
    harness.equal(owner:draws_used(), 7)
end

-- Okawaru's level-one pool selects an orc and keeps god attribution without
-- an expiry timer. The common owner supplies its actual ECS combat body.
local function okawaru_warrior(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = summon_context(ctx, player, { 0, 0 })

    ctx:add(player, component.PROGRESSION, { level = 1 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 20,
        y = 20,
    })

    okawaru.apply(owner, player)

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned, 2)
    harness.equal(ctx:get(summoned[2], component.ACTOR).kind_id,
        monsters.MONS_ORC)
    harness.equal(ctx:get(summoned[2], component.SUMMON).source_id,
        gods.OKAWARU)
    harness.equal(ctx:get(summoned[2], component.SUMMON).expires_aut, 0)
    harness.equal(owner:draws_used(), 2)
end

-- At XL1 Makhleb's servant branch has no greater-servant draws and sends
-- one lesser demon. The hostile actor carries the god as its saved source.
local function makhleb_servant(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = summon_context(ctx, player, { 1, 0, 0 })

    ctx:add(player, component.PROGRESSION, { level = 1 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 30,
        y = 30,
    })

    makhleb.apply(owner, player)

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned, 3)
    harness.equal(ctx:get(summoned[3], component.ACTOR).kind_id,
        monsters.MONS_HELLWING)
    harness.equal(ctx:get(summoned[3], component.SUMMON).source_id,
        gods.MAKHLEB)
    harness.equal(ctx:get(summoned[3], component.SUMMON).expires_aut, 0)
    harness.equal(owner:draws_used(), 3)
end

-- The spell half is deliberately explicit until a god-avatar spell caster
-- can preserve beam, resistance, and killer attribution.
local function unsupported_makhleb_spell(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = with_draws(ctx, { 0 })
    local success, message = pcall(makhleb.apply, owner, player)

    harness.falsy(success)
    harness.truthy(string.find(message,
        "unimplemented Makhleb destruction wrath", 1, true))
end

-- Force only the selected high-level roster entry, then exercise the real
-- base-draconian draw and saved hostile summon through the ordinary owner.
local function okawaru_draconian(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = summon_context(ctx, player, {
        0, 0, 0, 0, 0, 0,
    })
    local old_pick = pool.pick

    ctx:add(player, component.PROGRESSION, { level = 13 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 40,
        y = 40,
    })

    pool.pick = function()
        return requests.BASE_DRACONIAN
    end

    local success, message = pcall(okawaru.apply, owner, player)

    pool.pick = old_pick

    if not success then
        error(message)
    end

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned, 6)
    harness.equal(ctx:get(summoned[4], component.ACTOR).kind_id,
        monsters.MONS_BLACK_DRACONIAN)
    harness.equal(ctx:get(summoned[4], component.SUMMON).source_id,
        gods.OKAWARU)
end

-- At XL27 severity above thirteen sends at least two greater demons.
-- Zero draws select Executioners without any lesser substitutions.
local function makhleb_greater(ctx)
    local player = worshipper(ctx, gods.NO_GOD)
    local owner = summon_context(ctx, player, {
        1, 0, 0, 0, 0, 0, 0, 0, 0,
    })

    ctx:add(player, component.PROGRESSION, { level = 27 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 50,
        y = 50,
    })

    makhleb.apply(owner, player)

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned, 8)
    harness.equal(ctx:get(summoned[7], component.ACTOR).kind_id,
        monsters.MONS_EXECUTIONER)
    harness.equal(ctx:get(summoned[8], component.ACTOR).kind_id,
        monsters.MONS_EXECUTIONER)
    harness.equal(owner:draws_used(), 9)
end

function test.run(ctx)
    selection(ctx)
    escaped_card(ctx)
    dead_ignis(ctx)
    eligibility(ctx)
    sif_magic(ctx)
    sif_intelligence(ctx)
    sif_statuses(ctx)
    beogh_weapon(ctx)
    beogh_smite(ctx)
    okawaru_warrior(ctx)
    makhleb_servant(ctx)
    unsupported_makhleb_spell(ctx)
    okawaru_draconian(ctx)
    makhleb_greater(ctx)
end

return test
