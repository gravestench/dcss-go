-- These cases enter the production player-health owner, so final HP loss,
-- worship, ECS summons, and later reactions follow the real Lua path.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local causes = require("constants.damage_causes")
local component = require("constants.component")
local forms = require("constants.form_ids")
local gods = require("constants.gods")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")
local artefacts = require("ids.artefacts")
local artefact_kinds = require("constants.artefact_kinds")
local artefact_properties = require("ids.artefact_properties")
local clouds = require("ids.clouds")
local items = require("ids.items")
local jobs = require("ids.jobs")
local jewellery_fixture = require("tests.fixtures.jewellery")
local jewellery_slots = require("constants.jewellery_slots")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local player_health = require("policy.combat.player_health")
local mutation_records = require("policy.mutations.records")
local save_summons = require("policy.save.summons")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Another later reaction may speak after the one being tested. Search
-- for the source message without relying on its position in the batch.
local function contains_message(messages, wanted)
    for _, message in ipairs(messages) do
        if message == wanted then
            return true
        end
    end

    return false
end

-- Give the player the actual equipped links read by the shared equipment
-- policy; a loose inventory item does not count as a worn artefact.
local function wear_thief(ctx, player)
    local cloak = ctx:create()

    ctx:add(cloak, component.ITEM, {
        kind_id = items.ARM_CLOAK,
        quantity = 1,
        plus = 2,
        charges = 0,
        ego = "",
    })
    ctx:add(cloak, component.CARRIED_BY, {
        holder = player,
    })
    ctx:add(cloak, component.EQUIPPED, {
        slot = "cloak",
    })
    ctx:add(cloak, component.ITEM_ARTEFACT, {
        kind = "unique",
        unique_id = artefacts.UNRAND_THIEF,
        properties = {},
        known = {},
        flags = {},
    })

    return cloak
end

-- A random artefact keeps its rolled property IDs on the item component;
-- only the equipped link makes those properties active for the wearer.
local function carry_randart(ctx, player, item_id, slot,
    values, equipped)
    local item = ctx:create()

    ctx:add(item, component.ITEM, {
        kind_id = item_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(item, component.CARRIED_BY, {
        holder = player,
    })

    if equipped then
        ctx:add(item, component.EQUIPPED, {
            slot = slot,
        })
    end

    ctx:add(item, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = values,
        known = {},
        flags = {},
    })

    return item
end

-- World-cloud entities are the saved result of a fog burst, unlike a
-- message that might have been printed even when placement was blocked.
local function placed_clouds(ctx, kind_id)
    local count = 0

    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local cloud = ctx:get(entity, component.WORLD_CLOUD)

        if cloud.kind_id == kind_id then
            count = count + 1
        end
    end

    return count
end

-- Separate coordinates keep each hit's spawned entities from crowding
-- another case while all components still use the production schemas.
local function case_at(ctx, x, god_id, piety)
    local player = ctx:create()
    local game = fixture.context(ctx, player)
    local attacker = fixture.actor(ctx, monsters.MONS_GOBLIN,
        x, 5, 30)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = x,
        y = 7,
    })
    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = piety,
    })

    -- Zero draws exercise the first source species and minimum count.
    function game:random(_, bound)
        return 0
    end

    return game, player, attacker
end

-- Query saved summon origins rather than infer creation from the message.
local function god_summons(ctx, player, god_id)
    local found = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.owner == player and state.source_id == god_id then
            found[#found + 1] = entity
        end
    end

    return found
end

-- The source performs the quarter-HP gate before chance and count rolls.
-- A successful Xom roll shares one butterfly kind and saved damager target.
local function xom_butterflies(ctx)
    local game, player, attacker = case_at(ctx, 7, gods.XOM, 100)
    local messages = {}

    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    player_health.damage(game, player, 25, false,
        attacker, causes.HIT)

    local spawned = god_summons(ctx, player, gods.XOM)

    harness.equal(#spawned, 2, "Xom ejects two butterflies")

    for _, entity in ipairs(spawned) do
        local actor = ctx:get(entity, component.ACTOR)
        local state = ctx:get(entity, component.SUMMON)
        local target = ctx:get(entity, component.SUMMON_HAUNTING)

        harness.equal(actor.kind_id, monsters.MONS_BUTTERFLY)
        harness.equal(state.source_category, categories.GODS)
        harness.equal(state.attitude, attitudes.FRIENDLY)
        harness.equal(state.expires_aut, 180)
        harness.equal(target.target, attacker)

        local ai = ctx:get(entity, component.AI)

        ai.target_x = ai.target_x or 0
        ai.target_y = ai.target_y or 0
        ai.memory_until_aut = ai.memory_until_aut or 0

        save_summons.validate(game, entity, actor,
            ctx:get(entity, component.POSITION), ai, state, game:aut())

        -- A valid god category alone cannot launder an unrelated summon
        -- through restore as Xom's butterfly.
        local original_source = state.source_id

        state.source_id = gods.DITHMENOS

        local accepted = pcall(save_summons.validate,
            game, entity, actor,
            ctx:get(entity, component.POSITION), ai, state, game:aut())

        state.source_id = original_source

        harness.falsy(accepted,
            "restore rejects a forged god summon origin")
    end

    harness.truthy(contains_message(messages,
        "A shower of butterflies erupts from you!"))

    local below, survivor, source = case_at(ctx, 29, gods.XOM, 100)
    local butterfly_chance_draws = 0

    function below:random(stream, bound)
        if stream == streams.RELIGION and bound == 300 then
            butterfly_chance_draws = butterfly_chance_draws + 1
        end

        return 0
    end

    player_health.damage(below, survivor, 24, false,
        source, causes.HIT)

    harness.equal(#god_summons(ctx, survivor, gods.XOM), 0)
    harness.equal(butterfly_chance_draws, 0,
        "subthreshold Xom damage skips the butterfly chance")
end

-- Dithmenos has first claim on hit fog. Its high-piety threshold accepts
-- this quarter-HP hit, so the cloak of the Thief must not roll or emit.
local function fog_precedence(ctx)
    local game, player, attacker = case_at(ctx, 61,
        gods.DITHMENOS, 160)

    wear_thief(ctx, player)
    player_health.damage(game, player, 25, false,
        attacker, causes.HIT)

    harness.equal(placed_clouds(ctx, clouds.CLOUD_BLACK_SMOKE), 4,
        "Dithmenos smoke takes priority over the Thief")

    local thief_game, thief_player, source = case_at(ctx, 83,
        gods.NO_GOD, 0)

    wear_thief(ctx, thief_player)
    player_health.damage(thief_game, thief_player, 25, false,
        source, causes.HIT)

    harness.equal(placed_clouds(ctx, clouds.CLOUD_GREY_SMOKE), 8,
        "the Thief makes a larger random-colour fog bank")

    local xom_game, xom_player = case_at(ctx, 105,
        gods.XOM, 100)
    local prior_xom_clouds = placed_clouds(ctx,
        clouds.CLOUD_XOM_TRAIL)

    player_health.damage(xom_game, xom_player, 25, false,
        nil, causes.HIT)

    harness.equal(placed_clouds(ctx, clouds.CLOUD_XOM_TRAIL),
        prior_xom_clouds + 4,
        "Xom smoke is the final fog branch")

    local penanced, debtor, assailant = case_at(ctx, 127,
        gods.DITHMENOS, 160)
    local worship = ctx:get(debtor, component.RELIGION_WORSHIP)
    local prior_grey = placed_clouds(ctx, clouds.CLOUD_GREY_SMOKE)

    worship.penance[gods.DITHMENOS] = 1
    ctx:set(debtor, component.RELIGION_WORSHIP, worship)
    wear_thief(ctx, debtor)
    player_health.damage(penanced, debtor, 25, false,
        assailant, causes.HIT)

    harness.equal(placed_clouds(ctx, clouds.CLOUD_GREY_SMOKE),
        prior_grey + 8,
        "Dithmenos penance lets the Thief cloak react")

    local carried, holder, foe = case_at(ctx, 149,
        gods.NO_GOD, 0)
    local loose_cloak = wear_thief(ctx, holder)
    local before_carried = placed_clouds(ctx, clouds.CLOUD_GREY_SMOKE)

    ctx:remove(loose_cloak, component.EQUIPPED)
    player_health.damage(carried, holder, 25, false,
        foe, causes.HIT)

    harness.equal(placed_clouds(ctx, clouds.CLOUD_GREY_SMOKE),
        before_carried,
        "carried Thief cloak cannot make hit fog")

    local xom_fallback, worshipper = case_at(ctx, 171,
        gods.XOM, 100)
    local before_fallback = placed_clouds(ctx, clouds.CLOUD_XOM_TRAIL)

    wear_thief(ctx, worshipper)

    -- A failed cloak coinflip must still offer the Xom fog branch.
    function xom_fallback:random(stream, bound)
        if stream == streams.DAMAGE_REACTION and bound == 2 then
            return 1
        end

        return 0
    end

    player_health.damage(xom_fallback, worshipper, 25, false,
        nil, causes.HIT)

    harness.equal(placed_clouds(ctx, clouds.CLOUD_XOM_TRAIL),
        before_fallback + 4,
        "Xom smoke follows a missed Thief cloak roll")
end

-- At three stars the Dithmenos chance ramp starts at 75 piety, rather
-- than at the two-star breakpoint. A 35-HP hit is still below the gate.
local function fog_intermediate_piety(ctx)
    local game, player, attacker = case_at(ctx, 237,
        gods.DITHMENOS, 100)
    local before = placed_clouds(ctx, clouds.CLOUD_BLACK_SMOKE)
    local chance_draws = 0

    function game:random(stream, bound)
        if stream == streams.RELIGION then
            chance_draws = chance_draws + 1
        end

        return 0
    end

    player_health.damage(game, player, 35, false,
        attacker, causes.HIT)

    harness.equal(placed_clouds(ctx, clouds.CLOUD_BLACK_SMOKE),
        before, "three-star fog uses the correct piety ramp")
    harness.equal(chance_draws, 0,
        "impossible fog skips the religion chance draw")

    local guaranteed, survivor, source = case_at(ctx, 303,
        gods.DITHMENOS, 100)
    local before_guaranteed = placed_clouds(ctx,
        clouds.CLOUD_BLACK_SMOKE)
    local guaranteed_draws = 0

    function guaranteed:random(stream, bound)
        if stream == streams.RELIGION then
            guaranteed_draws = guaranteed_draws + 1
        end

        return 0
    end

    player_health.damage(guaranteed, survivor, 50, false,
        source, causes.HIT)

    harness.equal(placed_clouds(ctx, clouds.CLOUD_BLACK_SMOKE),
        before_guaranteed + 4,
        "a hit at the upper threshold guarantees fog")
    harness.equal(guaranteed_draws, 0,
        "guaranteed fog skips the religion chance draw")
end

-- Two worn *Corrode sources can contribute two degrees to one source
-- application. *Slow makes its own saved timer only on non-poison damage.
local function artefact_drawbacks(ctx)
    local game, player, attacker = case_at(ctx, 127,
        gods.NO_GOD, 0)
    local messages = {}

    carry_randart(ctx, player, items.WPN_DAGGER, "weapon", {
        [artefact_properties.CORRODE] = 1,
        [artefact_properties.SLOW] = 1,
    }, true)
    carry_randart(ctx, player, items.ARM_CLOAK, "cloak", {
        [artefact_properties.CORRODE] = 1,
    }, true)

    -- Every property trial succeeds. The second stack's anti-stacking
    -- check needs a one to grow instead of merely extending duration.
    function game:random(_, bound)
        if bound == 8 then
            return 1
        end

        return 0
    end

    -- The source Slow helper announces the first application, not only
    -- its eventual expiry, so a damaging artefact hit must be visible.
    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    player_health.damage(game, player, 25, false,
        attacker, causes.HIT)

    local corrosion = ctx:get(player, component.CORROSION)
    local slowed = ctx:get(player, component.PLAYER_SLOW)

    harness.truthy(corrosion, "worn *Corrode reacts to a hit")
    harness.equal(corrosion.stacks, 2,
        "two *Corrode sources give two protected degrees")
    harness.equal(corrosion.remaining_aut, 120,
        "one corrosion application extends duration once")
    harness.truthy(slowed, "worn *Slow reacts to a hit")
    harness.equal(slowed.remaining_aut, 150,
        "source Slow scales its initial duration by three halves")
    harness.truthy(contains_message(messages,
        "You feel yourself slow down."))

    local poison, victim, source = case_at(ctx, 149,
        gods.NO_GOD, 0)

    carry_randart(ctx, victim, items.WPN_DAGGER, "weapon", {
        [artefact_properties.CORRODE] = 1,
        [artefact_properties.SLOW] = 1,
    }, true)

    player_health.damage(poison, victim, 25, false,
        source, causes.POISON)

    harness.falsy(ctx:has(victim, component.CORROSION),
        "poison skips *Corrode")
    harness.falsy(ctx:has(victim, component.PLAYER_SLOW),
        "poison skips *Slow")

    local carried, holder, enemy = case_at(ctx, 171,
        gods.NO_GOD, 0)

    carry_randart(ctx, holder, items.WPN_DAGGER, "weapon", {
        [artefact_properties.CORRODE] = 1,
        [artefact_properties.SLOW] = 1,
    }, false)

    player_health.damage(carried, holder, 25, false,
        enemy, causes.HIT)

    harness.falsy(ctx:has(holder, component.CORROSION),
        "carried *Corrode is inactive")
    harness.falsy(ctx:has(holder, component.PLAYER_SLOW),
        "carried *Slow is inactive")

    local resistant, guarded, attacker = case_at(ctx, 215,
        gods.NO_GOD, 0)
    local ring = jewellery_fixture.carry(ctx, guarded,
        items.RING_RESIST_CORROSION)

    ctx:add(ring, component.EQUIPPED, {
        slot = jewellery_slots.LEFT,
    })

    carry_randart(ctx, guarded, items.WPN_DAGGER, "weapon", {
        [artefact_properties.CORRODE] = 1,
    }, true)
    carry_randart(ctx, guarded, items.ARM_CLOAK, "cloak", {
        [artefact_properties.CORRODE] = 1,
    }, true)

    player_health.damage(resistant, guarded, 25, false,
        attacker, causes.HIT)

    harness.falsy(ctx:has(guarded, component.CORROSION),
        "rCorr protects each of two triggered corrosion degrees")
end

-- The shared Slow rule must reject both innate Formicid stasis and Tree
-- Form stasis even when the artefact's independent trigger succeeds.
local function artefact_slow_stasis(ctx)
    local formicid, player, attacker = case_at(ctx, 259,
        gods.NO_GOD, 0)
    local identity = ctx:get(player, component.PLAYER)
    local messages = {}

    identity.species_id = species.SP_FORMICID
    ctx:set(player, component.PLAYER, identity)
    carry_randart(ctx, player, items.WPN_DAGGER, "weapon", {
        [artefact_properties.SLOW] = 1,
    }, true)

    function formicid:emit(_, message)
        messages[#messages + 1] = message
    end

    player_health.damage(formicid, player, 25, false,
        attacker, causes.HIT)

    harness.falsy(ctx:has(player, component.PLAYER_SLOW),
        "Formicid stasis blocks artefact Slow")
    harness.truthy(contains_message(messages,
        "Your stasis prevents you from being slowed."))

    local tree, transformed, foe = case_at(ctx, 281,
        gods.NO_GOD, 0)

    ctx:add(transformed, component.PLAYER_FORM, {
        form_id = forms.TREE,
        remaining_aut = 100,
    })
    carry_randart(ctx, transformed, items.WPN_DAGGER,
        "weapon", {
            [artefact_properties.SLOW] = 1,
        }, true)
    player_health.damage(tree, transformed, 25, false,
        foe, causes.HIT)

    harness.falsy(ctx:has(transformed, component.PLAYER_SLOW),
        "Tree Form stasis blocks artefact Slow")
end

-- Sanguine Armour resolves before artefact drawbacks in ouch.cc. The
-- named-stream observation catches accidental registration reordering.
local function mutation_before_artefact(ctx)
    local game, player, attacker = case_at(ctx, 193,
        gods.NO_GOD, 0)
    local streams_seen = {}

    mutation_records.grant_acquired(ctx, player,
        mutations.MUT_SANGUINE_ARMOUR, 1)
    carry_randart(ctx, player, items.WPN_DAGGER, "weapon", {
        [artefact_properties.SLOW] = 1,
    }, true)

    function game:random(stream, bound)
        streams_seen[#streams_seen + 1] = stream

        return 0
    end

    player_health.damage(game, player, 40, false,
        attacker, causes.HIT)

    harness.truthy(ctx:has(player, component.SANGUINE_ARMOUR))
    harness.truthy(ctx:has(player, component.PLAYER_SLOW))
    harness.equal(streams_seen[1], streams.MUTATION,
        "Sanguine Armour draws before artefact drawbacks")
end

-- Run this category after production modules have registered callbacks.
function test.run(ctx)
    xom_butterflies(ctx)
    fog_precedence(ctx)
    fog_intermediate_piety(ctx)
    artefact_drawbacks(ctx)
    artefact_slow_stasis(ctx)
    mutation_before_artefact(ctx)
end

return test
