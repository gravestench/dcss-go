-- Generated Pan lords have individual source-style names and colours. The
-- values belong to their saved actor, so messages and terminal cells agree.
local catalog = require("policy.catalog")
local component = require("constants.component")
local colour_ids = require("constants.pan_lord_colours")
local colors = require("policy.presentation.colors")
local display = require("policy.combat.monster_support.display")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local pan_lord = require("policy.population.pan_lord")
local profile = require("policy.combat.monster_profile")
local view = require("policy.presentation.view")

local test = {}

-- Both spell and appearance rolls use the real saved component schema. A
-- fixed stream makes the exceptional ETC_RANDOM and ordinary colour paths
-- reproducible without copying the roller into this test.
local function check_appearance(ctx, draw_value, expected_colour)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 20 + draw_value, 20, 100)
    local game = fixture.context(ctx, lord)

    function game:random(_, bound)
        return draw_value == 0 and 0 or bound - 1
    end

    local generated = pan_lord.roll(game, false)

    harness.truthy(type(generated.name) == "string" and
        generated.name:match("^[A-Z][a-z]+"),
        "lord name follows the source capitalized form")
    harness.equal(generated.colour_id, expected_colour,
        "lord colour follows its final source roll")

    ctx:add(lord, component.PANDEMONIUM_LORD, generated)

    local definition = catalog.get("monsters",
        monsters.MONS_PANDEMONIUM_LORD)
    local projected = profile.definition(ctx, lord, definition)
    local visible = view.entity(game, {
        role = "monster",
        kind_id = monsters.MONS_PANDEMONIUM_LORD,
        monster_entity_id = ctx:id(lord),
    })
    harness.equal(projected.name, generated.name,
        "saved name reaches the monster profile")
    harness.equal(projected.colour_id, generated.colour_id,
        "saved colour reaches the monster profile")
    harness.equal(display.name(game, lord), generated.name,
        "combat messages use the generated name")
    harness.equal(visible.name, generated.name,
        "terminal view uses the generated name")
    harness.equal(visible.color_id, generated.colour_id,
        "terminal view uses the generated colour")

    if visible.animated_color then
        visible.ui_roll = 0

        local first = view.entity_color(visible)

        visible.ui_roll = 14

        local last = view.entity_color(visible)

        harness.equal(first.fg, colors.nonblack_irgb[1],
            "first redraw uses the source nonblack palette")
        harness.equal(last.fg, colors.nonblack_irgb[15],
            "later redraw can change the saved random-effect colour")
    else
        local cell = view.entity_color(visible)

        harness.equal(cell.fg, colors.source[generated.colour_id],
            "ordinary generated colour stays fixed across redraws")
    end
end

-- A range of caller streams catches malformed names and illegal colours
-- from the normal morphology without redeclaring either production table.
local function check_generated_range()
    for seed = 1, 64 do
        local state = seed
        local random = {}

        function random:random(_, bound)
            state = (state * 48271) % 2147483647

            return state % bound
        end

        local generated = pan_lord.roll(random, false)

        harness.truthy(generated.name:match("^[A-Z][A-Za-z ]+$"),
            "generated name has source ASCII words")
        harness.truthy(#generated.name >= 4 and
            not generated.name:find("  ", 1, true) and
            generated.name:sub(-1) ~= " ",
            "generated name can pass save validation")
        harness.truthy(colour_ids.VALID[generated.colour_id],
            "generated colour can pass save validation")
    end
end

-- An exceptional one-in-ten roll saves the random-effect token; the
-- ordinary roll saves a concrete colour and never produces dark grey.
function test.run(ctx)
    check_appearance(ctx, 0, colour_ids.RANDOM_EFFECT)
    check_appearance(ctx, 1, "WHITE")
    check_generated_range()
end

return test
