-- Source ETC_RANDOM chooses one of the 15 nonblack IRGB colours each time
-- the client redraws. The draw is supplied by the UI, not the game RNG.
local clouds = require("ids.clouds")
local elements = require("constants.element_colours")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local view = require("policy.presentation.view")

local test = {}

-- Catalog monsters and clouds retain their source colour marker so the
-- client knows which visible cells need a fresh UI-only colour draw.
local function check_source_markers(ctx)
    local monster = view.entity(ctx, {
        role = "monster",
        kind_id = monsters.MONS_KILLER_KLOWN,
    })
    local cloud = view.entity(ctx, {
        role = "cloud",
        kind_id = clouds.CLOUD_CHAOS,
    })

    harness.equal(monster.color_id, elements.RANDOM,
        "catalog monster retains animated source colour")
    harness.truthy(monster.animated_color,
        "catalog monster asks for redraw animation")
    harness.equal(cloud.color_id, elements.RANDOM,
        "source cloud retains animated colour")
    harness.truthy(cloud.animated_color,
        "source cloud asks for redraw animation")
end

-- The source UI stream returns 0..14; Lua projects that draw to the
-- corresponding nonblack IRGB colour without touching any game stream.
local function check_random_palette()
    local first = view.entity_color({
        role = "monster",
        color_id = elements.RANDOM,
        animated_color = true,
        ui_roll = 0,
    })
    local last = view.entity_color({
        role = "monster",
        color_id = elements.RANDOM,
        animated_color = true,
        ui_roll = 14,
    })

    harness.equal(first.fg, 1, "first UI draw is source blue")
    harness.equal(last.fg, 15, "last UI draw is source white")

    local valid = pcall(view.entity_color, {
        role = "monster",
        color_id = elements.RANDOM,
        animated_color = true,
        ui_roll = 15,
    })

    harness.falsy(valid, "out-of-range UI colour draw is rejected")
end

-- Production presentation policies should preserve the source marker and
-- resolve only the transient terminal colour on each separate redraw.
function test.run(ctx)
    check_source_markers(ctx)
    check_random_palette()
end

return test
