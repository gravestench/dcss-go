-- A source monster owns a three-form set across spell requests. This test
-- imports the production catalog and component rather than copying either.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local selection = require("policy.monsters.polymorph_selection")

local test = {}

-- A second request must draw from the saved set instead of rolling another
-- weighted shortlist. This makes save/restore and repeated casting stable.
local function persistent_forms(ctx)
    local monster = fixture.actor(ctx, monsters.MONS_RAT, 42, 42, 10)
    local game = fixture.context(ctx, monster)
    local rat = catalog.get(categories.MONSTERS, monsters.MONS_RAT)
    local draws = 0

    game.random = function(_, _, bound)
        draws = draws + 1
        return bound - 1
    end

    selection.initialize(game, monster, rat)

    local saved = ctx:get(monster, component.MONSTER_POLYMORPH_SET)
    local after_creation = draws

    harness.truthy(saved and #saved.forms > 0,
        "created monster owns at least one legal form")
    harness.truthy(#saved.forms <= 3,
        "source stores no more than three forms")

    local first = selection.pick(game, monster)
    local second = selection.pick(game, monster)

    harness.equal(first.id, second.id,
        "same-power picks consult the persistent set")
    harness.equal(draws, after_creation + 2,
        "each later request makes only its uniform set draw")

    selection.replace(game, monster, first)

    local changed = ctx:get(monster, component.MONSTER_POLYMORPH_SET)

    harness.truthy(changed.forms[1] ~= first.id,
        "a transformed body never keeps its old species in its new set")
end

-- A corpse template is not a real destination even when it shares the
-- original monster's undead holiness and could live on the current floor.
local function corpse_templates_are_not_forms(ctx)
    local monster = fixture.actor(ctx, monsters.MONS_WIGHT, 48, 48, 12)
    local game = fixture.context(ctx, monster)
    local source = catalog.get(categories.MONSTERS, monsters.MONS_WIGHT)
    local zombie = catalog.get(categories.MONSTERS, monsters.MONS_ZOMBIE)

    harness.falsy(selection.eligible(game, monster, source, zombie, {
        level_id = 1,
        x = 48,
        y = 48,
    }), "zombie template cannot replace an undead body")

    ctx:add(monster, component.MONSTER_POLYMORPH_SET, {
        forms = { monsters.MONS_ZOMBIE },
    })

    local valid = pcall(selection.validate, game, monster, source)

    harness.falsy(valid, "restore rejects a forged corpse-form set")
end

-- Source classifies demon tiers from glyphs. An & lord remains immune even
-- if it is absent from the smaller summoning lists used elsewhere.
local function glyph_tier_and_stationary_forms(ctx)
    local lord = catalog.get(categories.MONSTERS, monsters.MONS_CEREBOV)
    local monster = fixture.actor(ctx, monsters.MONS_CEREBOV, 51, 51, 40)
    local game = fixture.context(ctx, monster)

    harness.equal(selection.demon_tier(lord), -1,
        "ampersand lord uses the source immune tier")
    selection.initialize(game, monster, lord)
    harness.falsy(ctx:has(monster, component.MONSTER_POLYMORPH_SET),
        "immune lord has no saved form set")

    local plant = catalog.get(categories.MONSTERS,
        monsters.MONS_OKLOB_PLANT)
    local fungus = catalog.get(categories.MONSTERS,
        monsters.MONS_BALLISTOMYCETE)

    harness.truthy(selection.eligible(game, nil, plant, fungus, {
        level_id = 1,
        x = 51,
        y = 51,
    }), "threatening stationary plants are eligible")
end

-- Coloured base draconians survive the source final gate only one time in
-- nine. This draw occurs after species eligibility, not when the set rolls.
local function coloured_draconian_gate(ctx)
    local monster = fixture.actor(ctx, monsters.MONS_RAT, 55, 55, 10)
    local game = fixture.context(ctx, monster)
    local rat = catalog.get(categories.MONSTERS, monsters.MONS_RAT)
    local draconian = catalog.get(categories.MONSTERS,
        monsters.MONS_RED_DRACONIAN)
    local draw = 1

    game.random = function(_, _, bound)
        harness.equal(bound, 9, "draconian gate uses one-in-nine draw")
        return draw
    end

    local position = {
        level_id = 1,
        x = 55,
        y = 55,
    }

    harness.falsy(selection.eligible(game, monster, rat,
        draconian, position), "most coloured draconian rolls fail")

    draw = 0

    harness.truthy(selection.eligible(game, monster, rat,
        draconian, position), "one-in-nine roll accepts the form")
end

-- The source's named Prince exception follows his original identity after
-- the first transformation; it is not limited to the current frog species.
local function prince_stays_nonhuman(ctx)
    local monster = fixture.actor(ctx, monsters.MONS_RAT, 57, 57, 10)
    local game = fixture.context(ctx, monster)

    ctx:add(monster, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_PRINCE_RIBBIT,
    })

    local rat = catalog.get(categories.MONSTERS, monsters.MONS_RAT)
    local human = catalog.get(categories.MONSTERS, monsters.MONS_HUMAN)

    harness.falsy(selection.eligible(game, monster, rat, human, {
        level_id = 1,
        x = 57,
        y = 57,
    }), "Prince Ribbit cannot take human form after an earlier change")
end

-- Run against the production Lua ECS schema and catalog on a sparse grid.
function test.run(ctx)
    persistent_forms(ctx)
    corpse_templates_are_not_forms(ctx)
    glyph_tier_and_stationary_forms(ctx)
    coloured_draconian_gate(ctx)
    prince_stays_nonhuman(ctx)
end

return test
