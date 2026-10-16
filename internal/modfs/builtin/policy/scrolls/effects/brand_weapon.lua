-- Source: item-use.cc:_handle_brand_weapon and _rebrand_weapon.
local brands = require("constants.weapon_brands")
local catalog = require("policy.catalog")
local choice = require("policy.scrolls.item_choice")
local component = require("constants.component")
local identification = require("policy.items.identification")
local item_ids = require("ids.items")
local pool = require("policy.inventory.brand_pool")
local scrolls = require("policy.scrolls")

local brand_weapon = {}

local messages = {
    [brands.VORPAL] = " emits a brilliant flash of light!",
    [brands.PROTECTION] = " projects an invisible shield of force!",
    [brands.FLAMING] = " is engulfed in flames!",
    [brands.FREEZING] = " is covered with a thin layer of ice!",
    [brands.DRAINING] = " craves living souls!",
    [brands.VAMPIRISM] = " thirsts for the lives of mortals!",
    [brands.VENOM] = " drips with poison.",
    [brands.ELECTROCUTION] = " crackles with electricity.",
    [brands.CHAOS] = " erupts in a glittering mayhem of colour.",
    [brands.SPECTRAL] = " acquires a faint afterimage.",
}

local function eligible(ctx, _, entity)
    local item = ctx:get(entity, component.ITEM)
    local kind = catalog.get("items", item.kind_id)

    return not ctx:has(entity, component.ITEM_ARTEFACT) and
        pool.eligible(kind)
end

function brand_weapon.prepare(ctx, player, request)
    return choice.prepare(ctx, player, request,
        "Brand which weapon?", "You have no brandable weapons.",
        eligible)
end

function brand_weapon.apply(ctx, player, request)
    local target = choice.target(ctx, request)
    local item = ctx:get(target, component.ITEM)
    local kind = catalog.get("items", item.kind_id)
    local old_name = identification.name(ctx, player, target)
    local old_brand = item.ego ~= "" and item.ego or brands.NORMAL

    item.ego = pool.roll(ctx, kind, old_brand)
    ctx:set(target, component.ITEM, item)
    identification.reveal_item(ctx, target, {
        properties = true,
    })
    ctx:emit("read", old_name .. messages[item.ego])
    ctx:emit("read", identification.name(ctx, player, target))
end

scrolls.register(item_ids.SCR_BRAND_WEAPON, brand_weapon)

return brand_weapon
