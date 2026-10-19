
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local sentinels = require("constants.monster_gear_sentinels")
local validation = require("content.validation")

local test = {}

-- Gear specs stay attached to their source monster, including explicit empty
-- brand rows that differ from absent optional gear.
local function source_rows_have_owners()
    local primary = 0
    local secondary = 0

    for _, definition in ipairs(catalog.all(categories.MONSTERS)) do
        local owned = definition.weapon_gear or {}

        if owned.primary then
            primary = primary + 1
        end

        if owned.secondary then
            secondary = secondary + 1
        end
    end

    harness.equal(primary, 162, "primary weapon owners")
    harness.equal(secondary, 16, "secondary weapon owners")

    local goblin = catalog.get(categories.MONSTERS, monsters.MONS_GOBLIN)
    local edmund = catalog.get(categories.MONSTERS, monsters.MONS_EDMUND)
    local joseph = catalog.get(categories.MONSTERS, monsters.MONS_JOSEPH)
    local rat = catalog.get(categories.MONSTERS, monsters.MONS_RAT)

    harness.equal(goblin.weapon_gear.primary.weapons[1].id,
        items.WPN_DAGGER, "Goblin source weapon")
    harness.truthy(goblin.weapon_gear.primary.brands == mod.null,
        "null Goblin brand list changed")
    harness.equal(#edmund.weapon_gear.primary.brands, 0,
        "empty Edmund brand list changed")
    harness.truthy(joseph.weapon_gear.secondary ~= nil,
        "Joseph lost secondary gear")
    harness.falsy(rat.weapon_gear, "Rat unexpectedly owns weapon gear")
end

-- Weighted weapon alternatives require a strictly positive weight.
local function invalid_weapon_weight_is_rejected()
    local goblin = catalog.get(categories.MONSTERS, monsters.MONS_GOBLIN)
    local choice = goblin.weapon_gear.primary.weapons[1]
    local original = choice.weight

    choice.weight = 0
    local valid, reason = pcall(validation.weapon_gear, { goblin })
    choice.weight = original

    harness.falsy(valid, "zero weapon weight was accepted")
    harness.truthy(reason:find("weight", 1, true),
        "invalid weapon error omits field")
end

-- A weapon sentinel cannot be accepted as a brand ID in a gear row.
local function invalid_brand_reference_is_rejected()
    local pikel = catalog.get(categories.MONSTERS, monsters.MONS_PIKEL)
    local choice = pikel.weapon_gear.primary.brands[1]
    local original = choice.id

    choice.id = sentinels.NO_WEAPON
    local valid, reason = pcall(validation.weapon_gear, { pikel })
    choice.id = original

    harness.falsy(valid, "weapon sentinel was accepted as a brand")
    harness.truthy(reason:find("unknown brand", 1, true),
        "invalid brand error omits rule")
end

-- Replace a valid weapon ID with a missing one and require source-site catalog validation.
local function invalid_weapon_reference_is_rejected()
    local goblin = catalog.get(categories.MONSTERS, monsters.MONS_GOBLIN)
    local choice = goblin.weapon_gear.primary.weapons[1]
    local original = choice.id

    choice.id = original .. "_MISSING"
    local valid, reason = pcall(validation.weapon_gear, { goblin })
    choice.id = original

    harness.falsy(valid, "missing weapon definition was accepted")
    harness.truthy(reason:find("unknown weapon", 1, true),
        "missing weapon error omits rule")
end

-- Catalog validation rejects monster gear that names a missing weapon definition.
function test.run()
    source_rows_have_owners()
    invalid_weapon_weight_is_rejected()
    invalid_weapon_reference_is_rejected()
    invalid_brand_reference_is_rejected()
end

return test
