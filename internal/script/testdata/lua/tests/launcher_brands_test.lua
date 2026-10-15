local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")
local ammunition = require("ids.ammunition")
local launcher_brands = require("policy.combat.launcher_brands")
local harness = require("tests.harness")

local test = {}

local function fixed_roll(value)
    local ctx = {}

    function ctx.random(_, stream, bound)
        harness.equal(stream, "melee", "launcher brands use melee RNG")
        harness.truthy(value < bound, "fixture draw fits its bound")

        return value
    end

    return ctx
end

local function check_catalog()
    local count = 0

    for _, definition in ipairs(catalog.all(categories.ITEMS)) do
        local weapon = definition.weapon

        if weapon and weapon.ammo_id ~= ammunition.NONE and
            type(weapon.brand_weights) == "table" then
            for _, weight in ipairs(weapon.brand_weights) do
                launcher_brands.check(weight.brand_id)
                count = count + 1
            end
        end
    end

    harness.equal(count, 28,
        "all seven branded launcher definitions have brand modules")
end

function test.run()
    check_catalog()

    local missile = { name = "arrow" }
    local defender = {
        name = "rat",
        resistances = {},
    }
    local ctx = fixed_roll(2)

    harness.equal(launcher_brands.apply(ctx, brands.VORPAL,
        missile, defender, 9), 1,
        "vorpal damage uses one source draw")

    local flaming, flame_message = launcher_brands.apply(ctx,
        brands.FLAMING, missile, defender, 9)

    harness.equal(flaming, 2,
        "flaming damage uses half the source draw plus one")
    harness.equal(flame_message, "The arrow burns the rat.",
        "flaming launcher uses the source hit message")

    local freezing, freeze_message = launcher_brands.apply(ctx,
        brands.FREEZING, missile, defender, 9)

    harness.equal(freezing, 2,
        "freezing damage uses half the source draw plus one")
    harness.equal(freeze_message, "The arrow freezes the rat.",
        "freezing launcher uses the source hit message")

    harness.equal(launcher_brands.apply(ctx, brands.NORMAL,
        missile, defender, 9), 0,
        "ordinary launchers add no brand damage")
    harness.equal(launcher_brands.apply(ctx, brands.FLAMING,
        missile, defender, 0), 0,
        "zero base damage cannot activate elemental brands")
end

return test
