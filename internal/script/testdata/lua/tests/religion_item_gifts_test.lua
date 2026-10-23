-- These cases run god gift rules against production ECS schemas and the
-- actual item generator. They never shadow the bundled item catalog.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local gifts = require("policy.religion.gifts")
local generation = require("policy.item_generation")
local gods = require("constants.gods")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local player_books = require("policy.magic.player_book_catalog")
local purpose = require("constants.item_generation_purpose")
local quality = require("constants.vault_item_quality")
local offers = require("policy.scrolls.acquirement_offers")
local source_level = require("policy.item_generation.source_level")
local skills = require("ids.skills")
local schools = require("constants.spell_schools")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local armour = require("policy.scrolls.acquirement.armour")
local weapons = require("policy.scrolls.acquirement.weapons")

local test = {}
local next_x = 2

-- The proxy scripts only religion RNG. Item generation uses its real named
-- streams and deterministic zero draws, preserving real item construction.
local function owner(ctx, god_id, points, draws, feature)
    local player = ctx:create()
    local x = next_x
    local index = 0
    local game = setmetatable({}, { __index = ctx })

    next_x = next_x + 2

    function game:player()
        return player
    end

    function game:cell()
        return feature or terrain.DNGN_FLOOR
    end

    function game:random(stream, bound)
        if stream == streams.RELIGION then
            index = index + 1

            local value = draws[index]

            harness.truthy(value, "missing scripted religion gift draw")
            harness.truthy(value < bound, "religion gift draw out of range")

            return value
        end

        return 0
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Gift tester",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = x,
        y = 2,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = points,
    })
    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        choices = {},
    })

    return game, player
end

-- A gift creates one normal floor item at this player, not a parallel
-- inventory record or an unclaimed acquirement-scroll reservation.
local function floor_gift(ctx, player)
    local position = ctx:get(player, component.POSITION)
    local found = {}

    for _, entity in ipairs(ctx:query({ component.ITEM, component.POSITION })) do
        local at = ctx:get(entity, component.POSITION)

        if at.level_id == position.level_id and at.x == position.x and
            at.y == position.y then
            found[#found + 1] = entity
        end
    end

    harness.equal(#found, 1)

    return found[1]
end

-- Sif never gifts a manual and a successful book is a real floor item.
local function sif_book(ctx)
    local game, player = owner(ctx, gods.SIF_MUNA, 200,
        { 199, 1, 0, 0 })

    harness.truthy(gifts.check(game, player))

    local entity = floor_gift(ctx, player)
    local item = ctx:get(entity, component.ITEM)
    local definition = catalog.get(categories.ITEMS, item.kind_id)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(definition.class, classes.OBJ_BOOKS)
    harness.truthy(item.kind_id ~= item_ids.BOOK_MANUAL)
    harness.equal(ctx:get(entity, component.ITEM_PROVENANCE)
        .god_id, gods.SIF_MUNA)
    harness.equal(ctx:get(entity, component.ITEM_PROVENANCE)
        .purpose, purpose.GOD_GIFT)
    harness.truthy(state.gift_timeout >= 10)
    harness.equal(state.gift_total[gods.SIF_MUNA], 1)
    harness.falsy(gifts.check(game, player))
end

-- Source terrain safety rejects the gift before item RNG and counters.
local function lava_rejects(ctx)
    local game, player = owner(ctx, gods.SIF_MUNA, 200, {},
        terrain.DNGN_LAVA)

    harness.falsy(gifts.check(game, player))
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_total[gods.SIF_MUNA], nil)
end

-- Source rejects the combination of no grasp and no armour before trying
-- an equipment subtype, even when high piety would otherwise allow one.
local function anatomy_rejects(ctx)
    local game, player = owner(ctx, gods.TROG, 200, {})

    for _, mutation_id in ipairs({
        mutations.MUT_NO_GRASPING,
        mutations.MUT_NO_ARMOUR,
    }) do
        local entity = ctx:create()

        ctx:add(entity, component.MUTATION, {
            owner = player,
            mutation_id = mutation_id,
            acquired = 1,
        })
    end

    harness.falsy(gifts.check(game, player))
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_total[gods.TROG], nil)
end

-- Trog uses the same acquisition owner but can only gift weapons.
local function trog_weapon(ctx)
    local game, player = owner(ctx, gods.TROG, 200,
        { 199, 0, 0, 0 })

    harness.truthy(gifts.check(game, player))

    local entity = floor_gift(ctx, player)
    local item = ctx:get(entity, component.ITEM)
    local definition = catalog.get(categories.ITEMS, item.kind_id)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(definition.class, classes.OBJ_WEAPONS)
    harness.equal(ctx:get(entity, component.ITEM_PROVENANCE)
        .god_id, gods.TROG)
    harness.truthy(state.gift_timeout >= 30)
    harness.equal(state.gift_total[gods.TROG], 1)
end

-- Okawaru's missile route is separate from the equipment roll and places
-- an actual usable throwing stack with the shorter source timeout.
local function oka_missiles(ctx)
    local game, player = owner(ctx, gods.OKAWARU, 200,
        { 0, 199, 0, 0, 0, 0 })

    harness.truthy(gifts.check(game, player))

    local entity = floor_gift(ctx, player)
    local item = ctx:get(entity, component.ITEM)
    local definition = catalog.get(categories.ITEMS, item.kind_id)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(definition.class, classes.OBJ_MISSILES)
    harness.equal(ctx:get(entity, component.ITEM_PROVENANCE)
        .god_id, gods.OKAWARU)
    harness.truthy(item.quantity >= 1)
    harness.truthy(state.gift_timeout >= 6)
    harness.equal(state.gift_total[gods.OKAWARU], 1)
end

-- Sif must fail quietly once every available player book spell has already
-- entered the library; it cannot manufacture a manual as a fallback.
local function sif_exhausted(ctx)
    local game, player = owner(ctx, gods.SIF_MUNA, 200,
        { 199, 1 })

    for _, spell in ipairs(player_books.ordered()) do
        local entity = ctx:create()

        ctx:add(entity, component.SPELL_RECORD, {
            owner = player,
            spell_id = spell.id,
            in_library = true,
        })
    end

    harness.falsy(gifts.check(game, player))
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_total[gods.SIF_MUNA], nil)
end

-- Okawaru weights equipment classes equally after the high-piety gate.
-- The scripted third draw selects armour and its two-part timeout.
local function oka_armour(ctx)
    local game, player = owner(ctx, gods.OKAWARU, 200,
        { 199, 0, 1, 0, 0, 0, 0 })

    harness.truthy(gifts.check(game, player))

    local entity = floor_gift(ctx, player)
    local item = ctx:get(entity, component.ITEM)

    harness.equal(catalog.get(categories.ITEMS, item.kind_id).class,
        classes.OBJ_ARMOUR)
    harness.truthy(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_timeout >= 60)
end

-- Source uses ISPEC_GIFT (350), distinct from the stronger unique odds of
-- ISPEC_GOOD_ITEM (351). A direct gift must preserve that distinction in
-- its generation request rather than borrowing the scroll quality.
local function gift_quality(ctx)
    local game = owner(ctx, gods.OKAWARU, 200, {})
    local gift = offers.roll_for_gift(game, classes.OBJ_MISSILES,
        1, gods.OKAWARU)

    harness.equal(gift.source.quality, quality.GIFT)
    harness.equal(source_level.request(gift.source).depth, 350)
    harness.equal(source_level.request({
        depth = 1,
        quality = quality.GOOD,
    }).depth, 351)
end

-- God's equipment choice uses source divine weights. Trog's last
-- permitted family is Staves; an acquirement scroll may reach Ranged.
local function divine_equipment_weights(ctx)
    local game, player = owner(ctx, gods.TROG, 200, {})
    local original_random = game.random
    local first_bound

    function game:random(stream, bound)
        if stream == streams.ITEM_GENERATION and not first_bound then
            first_bound = bound

            return bound - 1
        end

        return original_random(self, stream, bound)
    end

    local weapon_id = weapons.pick(game, player, 1, gods.TROG)
    local weapon = catalog.get(categories.ITEMS, weapon_id)

    harness.equal(first_bound, 6)
    harness.equal(weapon.weapon.skill_id, skills.SK_STAVES)

    first_bound = nil
    armour.pick(game, player, 1, gods.OKAWARU)

    harness.equal(first_bound, 10)
end

-- Source divine subtype rolls use only the base acquisition weight,
-- while scrolls boost high-damage melee bases after choosing a skill.
local function divine_weapon_subtype_weight(ctx)
    local game, player = owner(ctx, gods.OKAWARU, 200, {})
    local original_random = game.random
    local bounds = {}

    function game:random(stream, bound)
        if stream == streams.ITEM_GENERATION then
            bounds[#bounds + 1] = bound
        end

        return original_random(self, stream, bound)
    end

    weapons.pick(game, player, 1, gods.OKAWARU)

    local gift_total = bounds[2]

    bounds = {}
    weapons.pick(game, player, 1)

    harness.truthy(gift_total < bounds[2],
        "divine subtype weight should omit scroll damage bonus")
end

-- Sif keeps the old five-spell size for a level-one randbook. Ordinary
-- acquired level books shrink that source size to roughly three spells.
local function sif_level_book_size(ctx)
    local game = owner(ctx, gods.SIF_MUNA, 200, {})
    local rolled = generation.roll(game, {
        kind_id = item_ids.BOOK_RANDART_LEVEL,
        depth = 1,
        quality = quality.GIFT,
        purpose = purpose.GOD_GIFT,
        god_id = gods.SIF_MUNA,
        allow_uniques = false,
        acquirement_level = 1,
        exclude_known = true,
        site = "Sif level book size test",
    })

    harness.equal(#rolled.components[component.ITEM_RANDOM_BOOK].spells, 5)
end

-- A favorable source three-roll average can request eight themed spells.
-- The generator may use the whole range when eligible spells exist.
local function sif_themed_book_size(ctx)
    local game = owner(ctx, gods.SIF_MUNA, 200, {})
    local original_random = game.random
    local size_draws = 0

    function game:random(stream, bound)
        if stream == streams.ITEM_GENERATION and size_draws < 3 then
            size_draws = size_draws + 1

            return bound - 1
        end

        return original_random(self, stream, bound)
    end

    local rolled = generation.roll(game, {
        kind_id = item_ids.BOOK_RANDART_THEME,
        depth = 1,
        quality = quality.GIFT,
        purpose = purpose.GOD_GIFT,
        god_id = gods.SIF_MUNA,
        allow_uniques = false,
        disc = schools.CONJURATION,
        disc2 = schools.FIRE,
        slevels = 100,
        exclude_known = true,
        site = "Sif themed book size test",
    })

    harness.equal(#rolled.components[component.ITEM_RANDOM_BOOK].spells, 8)
end

-- Exercise all three god modules through the same shared dispatcher.
function test.run(ctx)
    sif_book(ctx)
    lava_rejects(ctx)
    anatomy_rejects(ctx)
    trog_weapon(ctx)
    oka_missiles(ctx)
    oka_armour(ctx)
    sif_exhausted(ctx)
    gift_quality(ctx)
    divine_equipment_weights(ctx)
    divine_weapon_subtype_weight(ctx)
    sif_level_book_size(ctx)
    sif_themed_book_size(ctx)
end

return test
