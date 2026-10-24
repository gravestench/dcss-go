-- Live slime tests use production schemas and the shared sparse grid.
-- Positions in this file are separate arenas so each case can inspect
-- its own actors without a second implementation of the game grid.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local slime = require("policy.monsters.slime_lifecycle")
local behaviors = require("constants.ai_behaviors")
local roster = require("policy.population.roster")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local catalog = require("policy.catalog")
local attitudes = require("constants.attitude")
local growth = require("policy.religion.jiyva.growth")

local test = {}

-- A focused live actor carries only the state this source ability reads;
-- component values still pass through the production ECS schema.
local function body(ctx, x, y, size, health)
    local entity = fixture.actor(ctx, monsters.MONS_SLIME_CREATURE,
        x, y, health)

    ctx:set(entity, component.HEALTH, {
        current = health,
        max = health,
    })
    ctx:add(entity, component.AI, {
        behavior = behaviors.SEEK,
        target_x = x + 5,
        target_y = y,
        memory_until_aut = 250,
        bat_retreat_actions = 0,
    })
    ctx:add(entity, component.MONSTER_ENERGY, {
        points = 70,
    })

    if size > 1 then
        ctx:add(entity, component.SLIME_BLOB, {
            size = size,
        })
    end

    return entity
end

-- A three-body group leaves two bodies with its parent and makes one
-- independently positioned child. HP is apportioned, not rerolled.
local function divides_three_bodies(ctx, game)
    ctx:set(game:player(), component.POSITION, {
        level_id = 1,
        x = 31,
        y = 20,
    })

    local parent = fixture.actor(ctx, monsters.MONS_SLIME_CREATURE,
        30, 20, 135)

    ctx:set(parent, component.HEALTH, {
        current = 135,
        max = 180,
    })
    ctx:add(parent, component.SLIME_BLOB, {
        size = 3,
    })
    ctx:add(parent, component.AI, {
        behavior = "seek",
        target_x = 31,
        target_y = 20,
        memory_until_aut = 250,
        bat_retreat_actions = 0,
    })
    ctx:add(parent, component.MONSTER_ENERGY, {
        points = 50,
    })
    ctx:add(parent, component.MONSTER_ARENA_DUEL, {
        current = true,
        abandoned = false,
        root_id = "original",
    })
    ctx:add(parent, component.JIYVA_GROWTH, {
        birth_max = 180,
        split_count = 0,
        born_from_split = false,
    })

    harness.truthy(slime.tick(game, parent),
        "a merged slime spends its action to split")

    local bodies = {}

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
    })) do
        local actor = ctx:get(entity, component.ACTOR)

        if actor.kind_id == monsters.MONS_SLIME_CREATURE then
            bodies[#bodies + 1] = entity
        end
    end

    harness.equal(#bodies, 2, "one additional body exists")
    harness.equal(ctx:get(parent, component.SLIME_BLOB).size, 2,
        "parent retains two blobs")
    harness.equal(ctx:get(parent, component.HEALTH).max, 120,
        "parent maximum scales to its share")
    harness.equal(ctx:get(parent, component.HEALTH).current, 90,
        "parent current HP scales to its share")

    local child = bodies[1] == parent and bodies[2] or bodies[1]
    local child_position = ctx:get(child, component.POSITION)

    harness.equal(child_position.level_id, 1,
        "offspring stays on the floor")
    harness.equal(ctx:get(child, component.HEALTH).max, 60,
        "offspring has one blob of maximum HP")
    harness.equal(ctx:get(child, component.HEALTH).current, 45,
        "offspring has one blob of current HP")
    harness.truthy(ctx:get(child, component.MONSTER_ARENA_DUEL).current,
        "offspring remains part of the same Duel")
    harness.truthy(ctx:has(child, component.SLIME_BIRTH),
        "offspring records its saved runtime origin")
    harness.equal(ctx:get(parent, component.JIYVA_GROWTH).split_count, 1,
        "feeding history records the parent's ordinary blob division")
    harness.truthy(ctx:get(child, component.JIYVA_GROWTH).born_from_split,
        "fed offspring keeps a valid growth lineage")
    harness.equal(ctx:get(parent, component.JIYVA_GROWTH).birth_max, 120,
        "parent's recorded base scales to its remaining blobs")
    harness.equal(ctx:get(child, component.JIYVA_GROWTH).birth_max, 60,
        "child's recorded base scales to its new blob count")

    local profile = roster.profile(monsters.MONS_SLIME_CREATURE)

    growth.validate(game, parent, ctx:get(parent, component.HEALTH), {
        minimum = profile.minimum * 2,
        maximum = profile.maximum * 2,
    }, 0)
    growth.validate(game, child, ctx:get(child, component.HEALTH),
        profile, 0)

    -- Feeding after division raises the saved maximum independently of
    -- the division's exact rounded value.
    local fed_health = ctx:get(child, component.HEALTH)

    fed_health.max = fed_health.max + 1
    ctx:set(child, component.HEALTH, fed_health)
    slime.validate(game, child, fed_health, profile, 0)
end

-- One occupied forward square is the only shorter route. The acting body
-- is dismissed without death, while the survivor owns both HP reservoirs.
local function blocked_route_merges(ctx, game)
    local source = body(ctx, 50, 20, 1, 20)
    local target = body(ctx, 51, 20, 2, 40)

    game.walls["51:19"] = true
    game.walls["51:21"] = true
    ctx:add(source, component.MONSTER_ARENA_DUEL, {
        current = true,
        abandoned = false,
        root_id = "lineage",
    })
    ctx:add(source, component.MONSTER_ENCHANT, {
        blind_aut = 0,
        corrosion_aut = 30,
        invisible_aut = 0,
    })
    ctx:add(source, component.STICKY_FLAME, {
        degree = 1,
        remaining_aut = 30,
        max_aut = 30,
        source = game:player(),
    })
    ctx:add(source, component.FLASH_FROZEN, {
        remaining_aut = 30,
    })
    ctx:add(source, component.PROJECTILE_SLOW, {
        base_speed = 10,
        remaining_aut = 30,
    })
    local slowed_actor = ctx:get(source, component.ACTOR)

    slowed_actor.speed = 7
    ctx:set(source, component.ACTOR, slowed_actor)
    ctx:add(source, component.JIYVA_GROWTH, {
        birth_max = 20,
        split_count = 1,
        born_from_split = true,
    })
    ctx:add(target, component.JIYVA_GROWTH, {
        birth_max = 40,
        split_count = 0,
        born_from_split = false,
    })

    harness.truthy(slime.tick(game, source),
        "blocked slime spends its action by merging")
    harness.equal(ctx:get(target, component.SLIME_BLOB).size, 3,
        "surviving actor owns all three blobs")
    harness.equal(ctx:get(target, component.HEALTH).current, 60,
        "current HP is pooled")
    harness.equal(ctx:get(target, component.HEALTH).max, 60,
        "maximum HP is pooled")
    harness.truthy(ctx:get(target, component.MONSTER_ARENA_DUEL).current,
        "Duel lineage survives body dismissal")
    harness.equal(ctx:get(target, component.MONSTER_ENCHANT).corrosion_aut,
        10, "source enchantment duration is weighted by blob count")
    harness.equal(ctx:get(target, component.STICKY_FLAME).remaining_aut,
        10, "source-only flame survives with weighted duration")
    harness.equal(ctx:get(target, component.FLASH_FROZEN).remaining_aut,
        10, "source-only freeze survives with weighted duration")
    harness.equal(ctx:get(target, component.PROJECTILE_SLOW).remaining_aut,
        10, "source-only slow keeps its weighted duration")
    harness.equal(ctx:get(target, component.ACTOR).speed, 7,
        "survivor inherits slowed live speed with the effect")
    harness.equal(ctx:get(target, component.JIYVA_GROWTH).birth_max, 60,
        "fed blob histories pool into the surviving body")
    harness.falsy(ctx:has(source, component.ACTOR),
        "consumed actor is removed without a death event")
end

-- A free advancing cell wins over combination. The source can move there
-- on its ordinary route instead of growing just because an ally is nearby.
local function open_route_stays_separate(ctx, game)
    local source = body(ctx, 70, 20, 1, 20)
    local target = body(ctx, 71, 20, 1, 20)

    harness.falsy(slime.tick(game, source),
        "an open advance blocks combination")
    harness.truthy(ctx:has(target, component.ACTOR),
        "neighbor remains its own actor")
end

-- The child may own the surviving ECS ID even though the original body
-- merges into it. Initial population ownership follows the HP lineage.
local function child_survivor_keeps_original_origin(ctx, game)
    local source = body(ctx, 75, 20, 1, 45)
    local child = body(ctx, 76, 20, 1, 45)

    game.walls["76:19"] = true
    game.walls["76:21"] = true
    ctx:add(child, component.SLIME_BIRTH, {
        created_aut = 0,
    })
    ctx:add(source, component.JIYVA_GROWTH, {
        birth_max = 45,
        split_count = 1,
        born_from_split = false,
    })
    ctx:add(child, component.JIYVA_GROWTH, {
        birth_max = 45,
        split_count = 1,
        born_from_split = true,
    })

    harness.truthy(slime.tick(game, source),
        "original body merges into its child")
    harness.falsy(ctx:has(child, component.SLIME_BIRTH),
        "survivor now spends the original roster slot")
    harness.falsy(ctx:get(child, component.JIYVA_GROWTH).born_from_split,
        "feeding history carries the original population role")
end

-- The source merge cap and real allegiance rule block two tempting but
-- invalid targets even when each sits on the only advancing cell.
local function incompatible_neighbors(ctx, game)
    local capped = body(ctx, 130, 20, 1, 20)
    local full = body(ctx, 131, 20, 5, 300)

    game.walls["131:19"] = true
    game.walls["131:21"] = true

    harness.falsy(slime.tick(game, capped),
        "six combined blobs exceed the source cap")
    harness.truthy(ctx:has(full, component.ACTOR),
        "a capped target remains separate")

    local hostile = body(ctx, 140, 20, 1, 20)
    local friendly = body(ctx, 141, 20, 1, 20)

    game.walls["141:19"] = true
    game.walls["141:21"] = true
    ctx:add(friendly, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    harness.falsy(slime.tick(game, hostile),
        "different real attitudes cannot combine")
end

-- A shapeshifter's borrowed slime form cannot grow a new blob lineage.
local function disabled_body(ctx, game)
    local shifter = body(ctx, 150, 20, 2, 80)

    ctx:add(shifter, component.MONSTER_SHAPESHIFTER, {
        variant_id = monsters.MONS_SHAPESHIFTER,
        original_kind_id = monsters.MONS_SHAPESHIFTER,
    })

    harness.falsy(slime.tick(game, shifter),
        "borrowed slime form does not divide")
end

-- The child marker admits only a real descendant of this species, and a
-- merged body's maximum remains bounded by its number of source profiles.
local function saved_lineage_is_bounded(ctx, game)
    local profile = roster.profile(monsters.MONS_SLIME_CREATURE)
    local valid = body(ctx, 90, 20, 2, profile.minimum * 2)

    ctx:add(valid, component.SLIME_BIRTH, {
        created_aut = 0,
    })
    slime.validate(game, valid, ctx:get(valid, component.HEALTH),
        profile, 0)

    local health = ctx:get(valid, component.HEALTH)

    health.max = profile.maximum * 2 + 1
    ctx:set(valid, component.HEALTH, health)

    local impossible = pcall(slime.validate, game, valid, health,
        profile, 0)

    harness.falsy(impossible, "oversized merged HP is rejected")

    local forged_blob = ctx:get(valid, component.SLIME_BLOB)

    forged_blob.reshaped_max = 10000
    ctx:set(valid, component.SLIME_BLOB, forged_blob)
    health.max = 10000
    ctx:set(valid, component.HEALTH, health)

    local self_attested = pcall(slime.validate, game, valid, health,
        profile, 0)

    harness.falsy(self_attested,
        "a saved reshaped marker cannot justify impossible HP")

    -- An authored source with a verified larger fixed roll may contribute
    -- to a merged maximum even after that source actor is dismissed.
    forged_blob.reshaped_max = 500
    ctx:set(valid, component.SLIME_BLOB, forged_blob)
    health.max = 500
    ctx:set(valid, component.HEALTH, health)

    local invented_source = pcall(slime.validate, game, valid,
        health, profile, 0, 50)

    harness.falsy(invented_source,
        "a larger authored source must be present in level metadata")

    local authored_pool = pcall(slime.validate, game, valid, health,
        profile, 0, 50, 300)

    harness.truthy(authored_pool,
        "an authored source HP cap admits a legal pooled maximum")

    forged_blob.size = 6
    ctx:set(valid, component.SLIME_BLOB, forged_blob)

    local excess_blobs = pcall(slime.validate, game, valid,
        health, profile, 0, 50, 300)

    harness.falsy(excess_blobs,
        "a saved slime cannot exceed the five-blob cap")

    local stranger = fixture.actor(ctx, monsters.MONS_RAT, 95, 20, 10)

    ctx:add(stranger, component.SLIME_BIRTH, {
        created_aut = 0,
    })

    local forged = pcall(slime.validate, game, stranger,
        ctx:get(stranger, component.HEALTH), profile, 0)

    harness.falsy(forged, "unrelated species cannot claim slime birth")

    local authored = body(ctx, 100, 20, 3, 300)

    -- DES can specify HP outside the ordinary roll. The authored fixed
    -- maximum remains valid for each blob after a source-shaped split.
    slime.validate(game, authored, ctx:get(authored, component.HEALTH),
        profile, 0, 100)

    local large_authored = body(ctx, 102, 20, 3, 18000)

    ctx:set(large_authored, component.SLIME_BLOB, {
        size = 3,
        reshaped_max = 18000,
    })
    slime.validate(game, large_authored,
        ctx:get(large_authored, component.HEALTH),
        profile, 0, 6000)

    local fed = body(ctx, 105, 20, 2, profile.maximum * 2 + 10)

    ctx:add(fed, component.JIYVA_GROWTH, {
        birth_max = profile.maximum * 2,
        split_count = 0,
        born_from_split = false,
    })
    slime.validate(game, fed, ctx:get(fed, component.HEALTH),
        profile, 0)
end

-- A body polymorphed into another species keeps its generated origin for
-- roster accounting, but no longer has the slime-only combat multiplier.
local function polymorph_discards_old_blob(ctx, game)
    local entity = body(ctx, 110, 20, 2, 110)

    ctx:add(entity, component.SLIME_BIRTH, {
        created_aut = 0,
    })
    polymorph.fixed(game, entity,
        catalog.get("monsters", monsters.MONS_RAT))

    harness.falsy(ctx:has(entity, component.SLIME_BLOB),
        "non-slime form has no stale blob size")
    harness.truthy(ctx:has(entity, component.SLIME_BIRTH),
        "birth origin remains for save accounting")
end

-- Two authored bodies can have distinct fixed HP per blob. Merging them
-- must retain a restorable pooled maximum, not the survivor's old formula.
local function mixed_authored_merge_is_restorable(ctx, game)
    local source = body(ctx, 160, 20, 1, 70)
    local target = body(ctx, 161, 20, 1, 50)

    game.walls["161:19"] = true
    game.walls["161:21"] = true
    ctx:add(target, component.VAULT_ACTOR_OVERRIDES, {
        fixed_hp = 50,
    })

    harness.truthy(slime.tick(game, source),
        "two authored slime bodies can merge")
    slime.validate(game, target, ctx:get(target, component.HEALTH),
        roster.profile(monsters.MONS_SLIME_CREATURE), 0, 50)
    harness.equal(ctx:get(target, component.HEALTH).max, 120,
        "the saved maximum is the sum of both bodies")
end

-- A polymorphed roster origin cannot govern the live slime body's HP.
local function polymorphed_slime_uses_live_profile(ctx, game)
    local profile = roster.profile(monsters.MONS_SLIME_CREATURE)
    local slime_form = body(ctx, 170, 20, 1, profile.maximum)

    ctx:add(slime_form, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_RAT,
    })
    slime.validate(game, slime_form,
        ctx:get(slime_form, component.HEALTH),
        profile, 0)
end

-- Both physical damage over time and the ordinary monster sight rule
-- remain in force across a division.
local function split_keeps_bodily_effects(ctx, game)
    ctx:set(game:player(), component.POSITION, {
        level_id = 1,
        x = 41,
        y = 30,
    })
    local parent = body(ctx, 40, 30, 2, 120)

    ctx:add(parent, component.STICKY_FLAME, {
        degree = 1,
        remaining_aut = 20,
        max_aut = 20,
        source = game:player(),
    })
    ctx:add(parent, component.FLASH_FROZEN, {
        remaining_aut = 10,
    })
    harness.truthy(slime.tick(game, parent), "affected slime divides")

    local child

    for _, entity in ipairs(ctx:query({ component.SLIME_BIRTH })) do
        if entity ~= parent then
            child = entity
        end
    end

    harness.truthy(child, "division created a child")
    harness.truthy(ctx:has(child, component.STICKY_FLAME),
        "fire remains on both split bodies")
    harness.truthy(ctx:has(child, component.FLASH_FROZEN),
        "frozen effect remains on both split bodies")
end

-- Feeding caps apply to each blob. Pooling two legal fed bodies may exceed
-- one body's cap without creating HP from nothing.
local function fed_merge_keeps_legal_ceiling(ctx, game)
    local definition = catalog.get("monsters", monsters.MONS_SLIME_CREATURE)
    local cap = math.floor(definition.average_hp_10x / 10) * 4
    local base = roster.profile(monsters.MONS_SLIME_CREATURE).minimum
    local source = body(ctx, 60, 30, 1, cap)
    local target = body(ctx, 61, 30, 1, cap)

    game.walls["61:29"] = true
    game.walls["61:31"] = true

    for _, entity in ipairs({ source, target }) do
        ctx:add(entity, component.JIYVA_GROWTH, {
            birth_max = base,
            split_count = 0,
            born_from_split = false,
        })
    end

    harness.truthy(slime.tick(game, source), "fed bodies combine")
    growth.validate(game, target, ctx:get(target, component.HEALTH), {
        minimum = base * 2,
        maximum = roster.profile(monsters.MONS_SLIME_CREATURE).maximum * 2,
    }, 0)
    slime.validate(game, target, ctx:get(target, component.HEALTH),
        roster.profile(monsters.MONS_SLIME_CREATURE), 0)
end

-- A hidden player is a route memory, not a currently visible foe whose
-- closer open square should veto division.
local function unseen_player_does_not_veto_split(ctx, game)
    local player = game:player()

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 33,
        y = 40,
    })
    ctx:add(player, component.POTION_INVISIBILITY, {
        remaining_aut = 100,
    })

    local parent = body(ctx, 30, 40, 2, 100)

    harness.truthy(slime.tick(game, parent),
        "an unseen foe does not turn an open cell into a split veto")
    ctx:remove(player, component.POTION_INVISIBILITY)
end

-- A zero draw makes the split coin flip and reservoir placement repeatable.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    game.random = function()
        return 0
    end

    divides_three_bodies(ctx, game)
    blocked_route_merges(ctx, game)
    open_route_stays_separate(ctx, game)
    child_survivor_keeps_original_origin(ctx, game)
    incompatible_neighbors(ctx, game)
    disabled_body(ctx, game)
    saved_lineage_is_bounded(ctx, game)
    polymorph_discards_old_blob(ctx, game)
    mixed_authored_merge_is_restorable(ctx, game)
    polymorphed_slime_uses_live_profile(ctx, game)
    split_keeps_bodily_effects(ctx, game)
    fed_merge_keeps_legal_ceiling(ctx, game)
    unseen_player_does_not_veto_split(ctx, game)
end

return test
