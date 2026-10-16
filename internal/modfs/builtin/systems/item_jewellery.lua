local jewellery = require("policy.inventory.jewellery")
local identification = require("policy.items.identification")
local intent_kinds = require("constants.intent")
local items = require("policy.inventory.items")
local kinds = require("constants.jewellery_kind")
local effects = require("policy.inventory.jewellery_effects")
local capabilities = require("constants.jewellery_capabilities")
local attunement = require("policy.jewellery.attunement")
local acrobat = require("policy.jewellery.acrobat")

local system = {}

local function refresh_magic(ctx, actor, before)
    local after = effects.sum(ctx, actor, capabilities.MAX_MP)

    if before ~= after then
        local resources = require("policy.character.resources")

        resources.refresh_mp(ctx, actor)
    end
end

local function ring_on(ctx, actor, intent)
    local magic_before = effects.sum(ctx, actor, capabilities.MAX_MP)
    local entity = intent.item_id
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")
    local slot = intent.target_id

    if not item or not carrier or carrier.holder ~= actor or
        jewellery.kind(items.kind(item)) ~= kinds.RING or
        not jewellery.slot_allowed(ctx, actor, kinds.RING, slot) or
        ctx:has(entity, "core.equipped") then
        error("invalid jewellery put-on intent")
    end

    local previous = jewellery.in_slot(ctx, actor, slot)

    if previous then
        ctx:remove(previous, "core.equipped")
        attunement.on_remove(ctx, previous)
        acrobat.equipment_changed(ctx, actor)
        ctx:emit("jewellery", "You remove " ..
            identification.name(ctx, actor, previous) .. ".")
    end

    ctx:add(entity, "core.equipped", { slot = slot })
    attunement.on_equip(ctx, actor, entity)
    refresh_magic(ctx, actor, magic_before)
    ctx:emit("jewellery", "You put on " ..
        identification.name(ctx, actor, entity) .. ".")
end

local function ring_off(ctx, actor, intent)
    local magic_before = effects.sum(ctx, actor, capabilities.MAX_MP)
    local entity = intent.item_id
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")
    local equipped = entity and ctx:get(entity, "core.equipped")

    if not item or not carrier or carrier.holder ~= actor or
        not equipped or
        jewellery.kind(items.kind(item)) ~= kinds.RING or
        not jewellery.slot_allowed(ctx, actor, kinds.RING, equipped.slot) then
        error("invalid jewellery removal intent")
    end

    ctx:remove(entity, "core.equipped")
    attunement.on_remove(ctx, entity)
    acrobat.equipment_changed(ctx, actor)
    refresh_magic(ctx, actor, magic_before)
    ctx:emit("jewellery", "You remove " ..
        identification.name(ctx, actor, entity) .. ".")
end

function system.update(ctx, actor)
    local intent = ctx:get(actor, "core.intent")

    if not intent or
        (intent.kind ~= intent_kinds.JEWELLERY_ON and
            intent.kind ~= intent_kinds.JEWELLERY_OFF) then
        return
    end

    if actor ~= ctx:player() then
        error("only the player can change jewellery")
    end

    if intent.kind == intent_kinds.JEWELLERY_ON then
        ring_on(ctx, actor, intent)
    else
        ring_off(ctx, actor, intent)
    end
end

register.system({
    id = "item.jewellery",
    scope = "active",
    query = {},
    after = { "item.drop" },
    before = { "item.quaff" },
    update = system.update,
})

return system
