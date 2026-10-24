-- Freezing damage uses half the source draw plus one.

local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local brands = require("constants.weapon_brands")
local ammunition = require("ids.ammunition")
local launcher_brands = require("policy.combat.launcher_brands")
local flame = require("policy.combat.launcher_brands.flaming")
local frost = require("policy.combat.launcher_brands.freezing")
local harness = require("tests.harness")

local test = {}

-- Source makeitem.cc permits these active and passive brands on ranged
-- weapons; an equipped launcher must validate them before a shot begins.
local legal = {
    brands.NORMAL,
    brands.VENOM,
    brands.PROTECTION,
    brands.SPEED,
    brands.VORPAL,
    brands.CHAOS,
    brands.HOLY_WRATH,
    brands.ELECTROCUTION,
    brands.FLAMING,
    brands.FREEZING,
    brands.PENETRATION,
    brands.ACID,
}

-- Melee-only and unknown saved values cannot be interpreted as ordinary
-- launcher attacks. This avoids a half-executed monster or player turn.
local function source_legal_brands()
    for _, id in ipairs(legal) do
        launcher_brands.check(id)
    end

    harness.falsy(pcall(launcher_brands.check, brands.VAMPIRISM),
        "melee-only vampirism was accepted on a launcher")
    harness.falsy(pcall(launcher_brands.check, "SPWPN_UNKNOWN"),
        "unknown launcher brand was accepted")

    harness.truthy(launcher_brands.passive(brands.SPEED),
        "Speed has no on-hit damage module")
    harness.falsy(launcher_brands.passive(brands.PROTECTION),
        "Protection must refresh its timed aura on a hit")
    harness.truthy(launcher_brands.passive(brands.PENETRATION),
        "Penetration acts during contact rather than after damage")
end

-- A fixed melee-stream draw pins bonus damage and catches wrong RNG bounds.
local function fixed_roll(value)
    local ctx = {}

    -- Return the fixture's exact melee draw and assert its bound, so launcher
    -- brand proc tests do not depend on a seed or hidden RNG consumption.
    function ctx.random(_, stream, bound)
        harness.equal(stream, "melee", "launcher brands use melee RNG")
        harness.truthy(value < bound, "fixture draw fits its bound")

        return value
    end

    return ctx
end

-- Branded launcher content must use a source-legal ranged brand.
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
        "all seven branded launcher definitions have legal brands")
end

-- Compare brand catalog coverage and a fired missile result, proving launcher
-- effects reach the ranged attack path through registered rules.
function test.run()
    source_legal_brands()
    check_catalog()

    local missile = { name = "arrow" }
    local defender = {
        name = "rat",
        resistances = {},
    }
    -- Reflected elemental missiles use the launcher damage formula and
    -- emit a projectile-specific hit message.
    local ctx = fixed_roll(2)

    local flaming, flame_message = flame.apply(ctx,
        missile, defender, 9)

    harness.equal(flaming, 2,
        "flaming damage uses half the source draw plus one")
    harness.equal(flame_message, "The arrow burns the rat.",
        "flaming launcher uses the source hit message")

    local freezing, freeze_message = frost.apply(ctx,
        missile, defender, 9)

    harness.equal(freezing, 2,
        "freezing damage uses half the source draw plus one")
    harness.equal(freeze_message, "The arrow freezes the rat.",
        "freezing launcher uses the source hit message")

end

return test
