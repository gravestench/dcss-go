-- Theory of operation: population calls roll once after an entrance has
-- survived placement. All source dice use the saved Trove generation stream;
-- the chosen value is written to the source marker and an Akara gate. Entry,
-- inspection, and restore read that saved value without drawing again.
-- Example: a mod can replace this module's roll policy while returning the
-- same validated price shape; its DES gate and travel policy need no edits.
local catalog = require("policy.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local ids = require("ids.items")
local classes = require("ids.object_classes")
local item_sets = require("policy.item_generation.item_sets")
local identification = require("policy.items.identification")
local pricing = require("policy.shops.pricing")
local sets = require("constants.item_sets")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local trove = require("constants.trove")
local terrain = require("constants.terrain")
local price_policies = require("policy.world.trove.prices.catalog")

local toll = {}

-- Draw source dice on the dedicated stream so combat and later floor
-- generation cannot alter a gate's displayed price.
local function die(ctx, sides)
    return ctx:random(streams.TROVE_TOLL, sides) + 1
end

-- Keep one fully shaped value for a consumable, equipment piece, or proof
-- rune. Source quantity and enchantment requirements have different meaning.
local function item_price(item_id, quantity, plus)
    return {
        kind = trove.PRICE_ITEM,
        item_id = item_id,
        quantity = quantity or 1,
        minimum_plus = plus or 0,
        ego_id = "",
        artefact_name = "",
        source_rune_index = 0,
    }
end

-- Rune tolls prove possession without consuming the saved rune progress.
-- The source's plus field is its rune enum index, not a rune count.
local function rune_price(item_id, source_rune_index)
    local price = item_price(item_id, 1, 0)

    price.kind = trove.PRICE_RUNE
    price.source_rune_index = source_rune_index

    return price
end

-- Append in source order. A later uniform draw chooses one offered price,
-- but dice for an earlier offered quantity have already been rolled.
local function add(prices, price)
    prices[#prices + 1] = price
end

-- The initial pool includes two named rune proofs and the horn. Fear and
-- the representative concealment scroll use source 2d3 quantities.
local function basic_prices(ctx, player, god_id)
    local prices = {}

    add(prices, item_price(ids.SCR_ACQUIREMENT, 2))
    add(prices, item_price(ids.SCR_FEAR, 2 + die(ctx, 3) + die(ctx, 3)))
    add(prices, rune_price(ids.RUNE_SLIME,
        trove.RUNE_SLIME_SOURCE_INDEX))
    add(prices, rune_price(ids.RUNE_ABYSSAL,
        trove.RUNE_ABYSSAL_SOURCE_INDEX))
    add(prices, item_price(ids.MISC_HORN_OF_GERYON, 1))

    local concealment = item_sets.choice(ctx, player,
        sets.CONCEALMENT_SCROLLS)

    if god_id ~= gods.OKAWARU or concealment ~= ids.SCR_BUTTERFLIES then
        add(prices, item_price(concealment,
            2 + die(ctx, 3) + die(ctx, 3)))
    end

    return prices
end

-- Source prepares every weapon quantity before the Felid exclusion, so
-- excluding weapons does not shift subsequent draws on this stream.
local function add_weapons(ctx, prices, species_id)
    local weapons = {
        item_price(ids.WPN_DEMON_WHIP, 1, 2 + die(ctx, 3) + die(ctx, 3)),
        item_price(ids.WPN_DEMON_TRIDENT, 1, 2 + die(ctx, 3) + die(ctx, 3)),
        item_price(ids.WPN_DEMON_BLADE, 1, 2 + die(ctx, 3) + die(ctx, 3)),
    }

    if species_id ~= species.SP_FELID then
        for _, price in ipairs(weapons) do
            add(prices, price)
        end
    end
end

-- The five dragon scales use their source enchantment bands. Octopodes
-- and Felids still consume those band rolls but cannot be offered armour.
local function add_armour(ctx, prices, species_id)
    local armour = {
        item_price(ids.ARM_GOLD_DRAGON_ARMOUR, 1, 1 + die(ctx, 2)),
        item_price(ids.ARM_STORM_DRAGON_ARMOUR, 1,
            die(ctx, 2) + die(ctx, 2)),
        item_price(ids.ARM_SHADOW_DRAGON_ARMOUR, 1,
            die(ctx, 2) + die(ctx, 2)),
        item_price(ids.ARM_FIRE_DRAGON_ARMOUR, 1,
            die(ctx, 3) + die(ctx, 3)),
        item_price(ids.ARM_ICE_DRAGON_ARMOUR, 1,
            die(ctx, 3) + die(ctx, 3)),
    }

    if species_id ~= species.SP_FELID and
        species_id ~= species.SP_OCTOPODE then
        for _, price in ipairs(armour) do
            add(prices, price)
        end
    end
end

-- Mummies cannot use potions, Vine Stalkers cannot heal by potion, and
-- Formicids cannot haste. Prebuilt common/healing offers retain source rolls.
local function add_potions(ctx, prices, species_id)
    local resistance = item_price(ids.POT_RESISTANCE, 2 + die(ctx, 3))
    local curing = item_price(ids.POT_CURING,
        12 + die(ctx, 4) + die(ctx, 4))
    local heal_wounds = item_price(ids.POT_HEAL_WOUNDS,
        8 + die(ctx, 3) + die(ctx, 3))

    if species_id == species.SP_MUMMY then
        return
    end

    add(prices, resistance)

    if species_id ~= species.SP_VINE_STALKER then
        add(prices, curing)
        add(prices, heal_wounds)
    end

    if species_id ~= species.SP_FORMICID then
        add(prices, item_price(ids.POT_HASTE,
            4 + die(ctx, 3) + die(ctx, 2)))
    end
end

-- Blink and teleport scroll offers are built for every species, but only
-- a character without Formicid stasis can be asked to surrender them.
local function add_stasis_scrolls(ctx, prices, species_id)
    local blinking = item_price(ids.SCR_BLINKING,
        2 + die(ctx, 3) + die(ctx, 3))
    local teleportation = item_price(ids.SCR_TELEPORTATION,
        10 + die(ctx, 4) + die(ctx, 4))

    if species_id ~= species.SP_FORMICID then
        add(prices, blinking)
        add(prices, teleportation)
    end
end

-- A source no-piety roll is considered before any item table. Exclusions
-- still consume that first roll, then use the ordinary item path.
local function no_piety_allowed(species_id, god_id)
    return species_id ~= species.SP_DEMIGOD and
        god_id ~= gods.GOZAG and
        god_id ~= gods.ASHENZARI and
        god_id ~= gods.USKAYAW and
        god_id ~= gods.YREDELEMNUL
end

-- `dgn.stash_items(1000, true)` considers high-value, nonstackable stock.
-- Read real Akara stock, quote it at the shop's saved greed, and preserve
-- stock order before the source's random candidate draw.
local function shop_stock(ctx)
    if not ctx.query then
        return {}
    end

    local candidates = {}

    for _, entity in ipairs(ctx:query({
        component.SHOP_STOCK,
        component.ITEM,
    })) do
        local stock = ctx:get(entity, component.SHOP_STOCK)
        local shop = ctx:entity(stock.shop_id)
        local state = shop and ctx:get(shop, component.SHOP)
        local item = ctx:get(entity, component.ITEM)
        local definition = catalog.get("items", item.kind_id)

        if state and state.open and
            ctx:remembered(state.level_id, state.x, state.y) ==
                terrain.DNGN_ENTER_SHOP and
            not definition.stackable and
            pricing.quote(ctx, shop, entity) >= 1000 then
            candidates[#candidates + 1] = {
                entity = entity,
                shop_id = stock.shop_id,
                order = stock.order,
            }
        end
    end

    table.sort(candidates, function(left, right)
        if left.shop_id ~= right.shop_id then
            return left.shop_id < right.shop_id
        end

        return left.order < right.order
    end)

    return candidates
end

-- An unidentified first stock pick receives one replacement draw in
-- source DCSS. Only identified weapons, armour, or jewellery may become
-- a gate price; no candidate leaves the fallback pool untouched.
local function shop_candidate(ctx, player)
    local candidates = shop_stock(ctx)

    if #candidates == 0 then
        return nil
    end

    local index = ctx:random(streams.TROVE_TOLL, #candidates) + 1
    local entity = candidates[index].entity
    local known = identification.known(ctx, player, entity)

    if not known.type or not known.properties or not known.pluses then
        index = ctx:random(streams.TROVE_TOLL, #candidates) + 1
        entity = candidates[index].entity
        known = identification.known(ctx, player, entity)
    end

    if not known.type or not known.properties or not known.pluses then
        return nil
    end

    local item = ctx:get(entity, component.ITEM)
    local definition = catalog.get("items", item.kind_id)

    if definition.class ~= classes.OBJ_WEAPONS and
        definition.class ~= classes.OBJ_ARMOUR and
        definition.class ~= classes.OBJ_JEWELLERY then
        return nil
    end

    local plus = 0

    if definition.class ~= classes.OBJ_JEWELLERY or
        definition.identification_has_pluses then
        plus = item.plus
    end

    local price = item_price(item.kind_id, item.quantity, plus)
    local artefact = ctx:get(entity, component.ITEM_ARTEFACT)

    price.ego_id = item.ego or ""
    price.artefact_name = artefact and artefact.name or ""

    return price
end

-- The fallback pool is built before choosing one item, matching the source
-- script's die order even for categories excluded by species or worship.
local function fallback_item(ctx, player, species_id, god_id)
    local prices = basic_prices(ctx, player, god_id)

    add_weapons(ctx, prices, species_id)
    add_armour(ctx, prices, species_id)
    add_potions(ctx, prices, species_id)
    add_stasis_scrolls(ctx, prices, species_id)

    return prices[ctx:random(streams.TROVE_TOLL, #prices) + 1]
end

-- Called only during population, after placement has settled the map.
-- The shop-item branch is retained as a separate decision point so a
-- stocked shop can supply the source's identified equipment toll.
function toll.roll(ctx, player)
    local choice = ctx:get(player, component.PLAYER)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local species_id = choice.species_id
    local god_id = worship and worship.god_id or gods.NO_GOD

    if ctx:random(streams.TROVE_TOLL, 20) == 0 and
        no_piety_allowed(species_id, god_id) then
        return {
            kind = trove.PRICE_NO_PIETY,
            item_id = "",
            quantity = 0,
            minimum_plus = 0,
            ego_id = "",
            artefact_name = "",
            source_rune_index = 0,
        }
    end

    if ctx:random(streams.TROVE_TOLL, 3) == 0 then
        local stocked = shop_candidate(ctx, player)

        if stocked then
            return stocked
        end
    end

    return fallback_item(ctx, player, species_id, god_id)
end

-- Reject malformed modded prices before they can be written into a saved
-- gate. A rune ID must actually resolve to the rune item class.
function toll.valid(price)
    if type(price) ~= "table" or type(price.kind) ~= "string" or
        price.kind == "" or price.kind:find("|", 1, true) then
        return false
    end

    local ego_id = price.ego_id or ""
    local artefact_name = price.artefact_name or ""
    local source_index = price.source_rune_index or 0

    if type(ego_id) ~= "string" or
        type(artefact_name) ~= "string" or
        ego_id:find("|", 1, true) or
        artefact_name:find("|", 1, true) or
        type(source_index) ~= "number" or
        source_index < 0 or source_index % 1 ~= 0 then
        return false
    end

    if price.kind ~= trove.PRICE_ITEM and
        price.kind ~= trove.PRICE_RUNE and
        price.kind ~= trove.PRICE_NO_PIETY then
        local policy = price_policies.get(price.kind)

        if type(price.item_id) ~= "string" or
            price.item_id:find("|", 1, true) or
            type(price.quantity) ~= "number" or
            price.quantity < 0 or price.quantity % 1 ~= 0 or
            type(price.minimum_plus) ~= "number" or
            price.minimum_plus < -100 or price.minimum_plus > 100 or
            price.minimum_plus % 1 ~= 0 then
            return false
        end

        return policy ~= nil and policy.valid(price)
    end

    if price.kind == trove.PRICE_NO_PIETY then
        return price.item_id == "" and price.quantity == 0 and
            price.minimum_plus == 0 and source_index == 0 and
            ego_id == "" and artefact_name == ""
    end

    if type(price.item_id) ~= "string" or
        type(price.quantity) ~= "number" or
        price.quantity < 1 or price.quantity % 1 ~= 0 or
        type(price.minimum_plus) ~= "number" or
        price.minimum_plus < -100 or price.minimum_plus > 100 or
        price.minimum_plus % 1 ~= 0 then
        return false
    end

    local okay, definition = pcall(catalog.get, "items", price.item_id)

    if not okay or not definition then
        return false
    end

    if price.kind == trove.PRICE_RUNE then
        return definition.class == classes.OBJ_RUNES and
            price.quantity == 1 and price.minimum_plus == 0 and
            ego_id == "" and artefact_name == ""
    end

    return definition.class ~= classes.OBJ_RUNES and
        source_index == 0
end

-- A canonical field order makes the marker a compact witness to the ECS
-- price. Stable IDs and names cannot contain the separator in this format.
function toll.encode(price)
    if not toll.valid(price) then
        error("invalid Trove price")
    end

    return table.concat({
        price.kind,
        price.item_id or "",
        tostring(price.quantity or 0),
        tostring(price.minimum_plus or 0),
        price.ego_id or "",
        price.artefact_name or "",
        tostring(price.source_rune_index or 0),
    }, "|")
end

return toll
