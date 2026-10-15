local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local identification = require("policy.items.identification")
local item_ids = require("ids.items")
local appearances = require("policy.items.appearances")
local modals = require("policy.presentation.modals")
local classes = require("ids.object_classes")
local cosmetics = require("constants.item_cosmetics")
local brands = require("constants.weapon_brands")
local pools = require("constants.appearance_pools")

local test = {}

local function item(ctx, id, plus, ego)
    local entity = ctx:create()
    local fields = {
        kind_id = id,
        quantity = 1,
        plus = plus or 0,
        charges = 0,
        ego = ego or "",
    }

    ctx:add(entity, component.ITEM, fields)

    return entity
end

function test.run(ctx)
    local player = ctx:create()
    identification.initialize(ctx, player)
    identification.validate(ctx, player)
    local extension = {
        class = catalog.get("items", item_ids.POT_CURING).class,
        identification_pool = pools.POTION,
        name = "potion of extension",
    }

    harness.equal(appearances.pool(extension), pools.POTION,
        "a mod item can join an existing appearance pool by metadata")

    local custom_amulet = {
        class = classes.OBJ_JEWELLERY,
        id = "MOD_CUSTOM_AMULET",
        name = "ancestor's charm",
    }

    harness.falsy(pcall(appearances.pool, custom_amulet),
        "custom jewellery needs explicit appearance metadata")
    custom_amulet.identification_pool = pools.AMULET
    harness.equal(appearances.pool(custom_amulet), pools.AMULET,
        "an explicitly classified amulet uses the amulet pool")

    local first = item(ctx, item_ids.POT_CURING)
    local floor_copy = item(ctx, item_ids.POT_CURING)
    local other = item(ctx, item_ids.POT_MIGHT)
    local hidden = identification.name(ctx, player, first)

    harness.equal(hidden, identification.name(ctx, player, floor_copy),
        "the same type has the same unknown appearance")
    harness.truthy(hidden ~= identification.name(ctx, player, other),
        "different potion types have distinct appearances")
    harness.falsy(hidden:find("curing", 1, true),
        "unknown potion name does not reveal its type")

    identification.reveal_type(ctx, player, first)

    harness.equal(identification.name(ctx, player, floor_copy),
        catalog.get("items", item_ids.POT_CURING).name,
        "discovery changes a matching floor copy")

    local weapon = item(ctx, item_ids.WPN_DAGGER, 3)
    local other_weapon = item(ctx, item_ids.WPN_DAGGER, 3)
    local zero_weapon = item(ctx, item_ids.WPN_DAGGER, 0)
    local branded = item(ctx, item_ids.WPN_DAGGER, 0,
        brands.FLAMING)
    local robe = item(ctx, item_ids.ARM_ROBE, 0)
    local scarf = item(ctx, item_ids.ARM_SCARF, 0)

    ctx:add(weapon, component.ITEM_IDENTIFICATION, {
        cosmetic = cosmetics.RUNED,
    })
    harness.equal(identification.name(ctx, player, weapon),
        "runed dagger", "unknown plus retains physical cosmetic")

    harness.falsy(identification.name(ctx, player, weapon):find("+3",
        1, true), "unknown plus is hidden")

    identification.reveal_item(ctx, weapon, {
        pluses = true,
    })

    harness.truthy(identification.name(ctx, player, weapon):find("+3",
        1, true), "known plus is shown")
    harness.falsy(identification.name(ctx, player, other_weapon):find("+3",
        1, true), "plus knowledge belongs to one physical item")
    identification.reveal_item(ctx, zero_weapon, {
        pluses = true,
    })
    identification.reveal_item(ctx, robe, {
        pluses = true,
    })
    identification.reveal_item(ctx, scarf, {
        pluses = true,
    })
    harness.equal(identification.name(ctx, player, zero_weapon),
        "+0 dagger", "a known zero weapon plus is visible")
    harness.equal(identification.name(ctx, player, robe),
        "+0 robe", "an enchantable robe shows a known zero plus")
    harness.equal(identification.name(ctx, player, scarf),
        "scarf", "unenchantable scarves omit pluses")
    harness.equal(identification.name(ctx, player, branded),
        "dagger", "hidden brand is not named")
    identification.reveal_item(ctx, branded, {
        properties = true,
    })
    harness.equal(identification.name(ctx, player, branded),
        "dagger of flaming", "known brand uses its source name")

    ctx:add(other, component.ITEM_IDENTIFICATION, {
        cosmetic = cosmetics.GLOWING,
    })
    harness.falsy(pcall(identification.validate, ctx, player),
        "consumables cannot hold armour or weapon cosmetics")
    ctx:remove(other, component.ITEM_IDENTIFICATION)

    local known = ctx:get(player, component.ITEM_KNOWLEDGE)
    local before = known.appearance_seeds[item_ids.POT_MIGHT]
    known.appearance_seeds[item_ids.POT_MIGHT] =
        known.appearance_seeds[item_ids.POT_CURING]
    ctx:set(player, component.ITEM_KNOWLEDGE, known)

    local valid = pcall(identification.validate, ctx, player)
    harness.falsy(valid, "duplicate saved appearances are rejected")

    known.appearance_seeds[item_ids.POT_MIGHT] = before
    ctx:set(player, component.ITEM_KNOWLEDGE, known)
    identification.validate(ctx, player)

    known.known_types["POT_NOT_IN_CATALOG"] = true
    ctx:set(player, component.ITEM_KNOWLEDGE, known)
    harness.falsy(pcall(identification.validate, ctx, player),
        "unknown saved type knowledge is rejected")
    known.known_types["POT_NOT_IN_CATALOG"] = nil
    ctx:set(player, component.ITEM_KNOWLEDGE, known)
    identification.validate(ctx, player)

    local modal = modals.rows({
        mode = "evoke_wand",
        height = 24,
        inventory = {
            {
                class = classes.OBJ_WANDS,
                name = "unknown wand",
                quantity = 1,
                charges = 99,
            },
        },
    })

    for _, write in ipairs(modal.writes) do
        harness.falsy(write.text:find("99 charges", 1, true),
            "inventory modal does not expose hidden wand charges")
    end
end

return test
