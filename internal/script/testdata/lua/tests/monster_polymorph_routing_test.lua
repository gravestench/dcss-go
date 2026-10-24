-- Source polymorph routing changes a shifter's borrowed body back to its
-- permanent variant and divides a merged slime before changing its bodies.
-- These cases use the production schemas and shared sparse grid fixture.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local power = require("constants.polymorph_power")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local ugly = require("policy.monsters.ugly_thing")

local test = {}

-- A spell on a borrowed shifter reveals its permanent form instead of
-- selecting another arbitrary species. The durable component is the owner.
local function shifter_reverts(ctx, game)
    local target = fixture.actor(ctx, monsters.MONS_RAT, 20, 20, 10)

    ctx:add(target, component.MONSTER_SHAPESHIFTER, {
        variant_id = monsters.MONS_GLOWING_SHAPESHIFTER,
        original_kind_id = monsters.MONS_GLOWING_SHAPESHIFTER,
    })
    ctx:add(target, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_GLOWING_SHAPESHIFTER,
    })

    local source = catalog.get(categories.MONSTERS, monsters.MONS_RAT)

    harness.truthy(polymorph.monster(game, target, source,
        streams.SPELL, power.SAME), "borrowed shifter accepts polymorph")
    harness.equal(ctx:get(target, component.ACTOR).kind_id,
        monsters.MONS_GLOWING_SHAPESHIFTER,
        "polymorph returns the shifter to its permanent variant")
end

-- The fixed reversion still passes source destination validation. A body
-- already in its permanent form cannot reroll HP, and a land-only variant
-- cannot replace a flying borrowed form above deep water.
local function shifter_reversion_requires_legal_site(ctx, game)
    local already = fixture.actor(ctx, monsters.MONS_SHAPESHIFTER,
        30, 30, 20)

    ctx:add(already, component.MONSTER_SHAPESHIFTER, {
        variant_id = monsters.MONS_SHAPESHIFTER,
        original_kind_id = monsters.MONS_SHAPESHIFTER,
    })

    local original_health = ctx:get(already, component.HEALTH)
    local variant = catalog.get(categories.MONSTERS,
        monsters.MONS_SHAPESHIFTER)

    harness.falsy(polymorph.monster(game, already, variant,
        streams.SPELL, power.SAME),
        "a shifter already in base form has no destination change")
    harness.equal(ctx:get(already, component.HEALTH).max,
        original_health.max, "rejected reversion does not reroll HP")

    local flying = fixture.actor(ctx, monsters.MONS_BAT, 35, 35, 20)

    ctx:add(flying, component.MONSTER_SHAPESHIFTER, {
        variant_id = monsters.MONS_SHAPESHIFTER,
        original_kind_id = monsters.MONS_SHAPESHIFTER,
    })
    game.cells["35:35"] = terrain.DNGN_DEEP_WATER

    harness.falsy(polymorph.monster(game, flying,
        catalog.get(categories.MONSTERS, monsters.MONS_BAT),
        streams.SPELL, power.SAME),
        "a land-only shifter form cannot return over deep water")
    harness.equal(ctx:get(flying, component.ACTOR).kind_id,
        monsters.MONS_BAT, "unsafe reversion leaves borrowed body intact")
end

-- Source checks an ugly body's colour mutation before the permanent
-- shapeshifter enchantment. The borrowed ugly form therefore stays ugly.
local function ugly_shifter_keeps_species(ctx, game)
    local target = fixture.actor(ctx, monsters.MONS_UGLY_THING,
        25, 25, 10)
    local source = catalog.get(categories.MONSTERS,
        monsters.MONS_UGLY_THING)

    ctx:add(target, component.UGLY_THING,
        ugly.roll(game, source, nil, nil, streams.MONSTER_TRAITS))
    ctx:add(target, component.MONSTER_SHAPESHIFTER, {
        variant_id = monsters.MONS_SHAPESHIFTER,
        original_kind_id = monsters.MONS_SHAPESHIFTER,
    })

    local previous = ctx:get(target, component.UGLY_THING)

    harness.truthy(polymorph.monster(game, target, source,
        streams.SPELL, power.SAME),
        "ugly shifter accepts a polymorph request")
    harness.equal(ctx:get(target, component.ACTOR).kind_id,
        monsters.MONS_UGLY_THING,
        "ugly mutation takes priority over shifter reversion")
    harness.truthy(ctx:get(target, component.UGLY_THING).adjective ~=
        previous.adjective,
        "spell forces an ugly colour change without adjacent energy")
end

-- The source's four-in-five branch forces a split without the ordinary
-- one-in-two action roll. Each resulting actor then gets a separate form.
local function merged_slime_divides(ctx, game)
    local target = fixture.actor(ctx, monsters.MONS_SLIME_CREATURE,
        40, 40, 90)

    ctx:set(target, component.HEALTH, {
        current = 90,
        max = 90,
    })
    ctx:add(target, component.SLIME_BLOB, {
        size = 3,
    })

    local draws = {}

    game.random = function(_, stream, bound)
        draws[#draws + 1] = { stream = stream, bound = bound }
        return 0
    end

    local source = catalog.get(categories.MONSTERS,
        monsters.MONS_SLIME_CREATURE)

    harness.truthy(polymorph.monster(game, target, source,
        streams.SPELL, power.SAME), "merged slime accepts polymorph")

    local transformed = 0
    local offspring = 0

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
    })) do
        local position = ctx:get(entity, component.POSITION)

        if position.x >= 39 and position.x <= 41 and
            position.y >= 39 and position.y <= 41 then
            transformed = transformed + 1

            harness.truthy(ctx:get(entity, component.ACTOR).kind_id ~=
                monsters.MONS_SLIME_CREATURE,
                "each slime body gets its own changed form")

            if ctx:has(entity, component.SLIME_BIRTH) then
                offspring = offspring + 1
            end
        end
    end

    harness.truthy(transformed > 1,
        "merged slime divides into several actors")
    harness.equal(offspring, transformed - 1,
        "new actors retain source split birth lineage")

    local first_slime_draw

    for _, draw in ipairs(draws) do
        if draw.stream == streams.SLIME_CREATURE then
            first_slime_draw = draw
            break
        end
    end

    harness.equal(first_slime_draw.bound, 2,
        "forced split consumes the source coin flip before placement")
end

-- slime_creature_polymorph always asks the persistent-set picker for its
-- next form, even when the requesting effect asks for LESS or MORE power.
local function slime_uses_same_picker(ctx, game)
    local target = fixture.actor(ctx, monsters.MONS_SLIME_CREATURE,
        60, 60, 30)
    local source = catalog.get(categories.MONSTERS,
        monsters.MONS_SLIME_CREATURE)
    local relative_draws = 0

    game.random = function(_, _, bound)
        if bound == 200 then
            relative_draws = relative_draws + 1
        end

        return 0
    end

    harness.truthy(polymorph.less(game, target, source, streams.SPELL),
        "a weaker request still changes the slime's body")
    harness.equal(relative_draws, 0,
        "slime routing bypasses relative-power random sampling")
end

-- No free neighboring grid cell prevents division, but the source still
-- polymorphs the original slime rather than silently dropping the spell.
local function blocked_slime_changes(ctx, game)
    local target = fixture.actor(ctx, monsters.MONS_SLIME_CREATURE,
        70, 70, 90)

    ctx:add(target, component.SLIME_BLOB, {
        size = 3,
    })

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(70 + dx) .. ":" .. (70 + dy)] = true
            end
        end
    end

    local source = catalog.get(categories.MONSTERS,
        monsters.MONS_SLIME_CREATURE)

    harness.truthy(polymorph.monster(game, target, source,
        streams.SPELL, power.SAME), "blocked merged slime still accepts spell")
    harness.truthy(ctx:get(target, component.ACTOR).kind_id ~=
        monsters.MONS_SLIME_CREATURE,
        "blocked merged slime changes the surviving body")
end

-- The same route serves all source monster polymorph callers. A single
-- observed context keeps actor identities real and locations disjoint.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    game.random = function()
        return 0
    end

    shifter_reverts(ctx, game)
    shifter_reversion_requires_legal_site(ctx, game)
    ugly_shifter_keeps_species(ctx, game)
    merged_slime_divides(ctx, game)
    slime_uses_same_picker(ctx, game)
    blocked_slime_changes(ctx, game)
end

return test
