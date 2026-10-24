-- Xom makes two different gifts. Random gifts use ordinary item weights
-- at a severity-scaled depth; acquirement chooses a class first and uses
-- the shared god-gift selector. Both become real, saved floor items.
local channels = require("constants.message_channels")
local classes = require("ids.object_classes")
local component = require("constants.component")
local events = require("ids.xom_events")
local generation = require("policy.item_generation")
local gifts = require("policy.religion.gifts.items")
local gods = require("constants.gods")
local purpose = require("constants.item_generation_purpose")
local quality = require("constants.vault_item_quality")
local streams = require("constants.rng_streams")

local effect = {}

-- Keep source class order explicit. The RNG chooses one index, while the
-- item catalog and gift owner decide its current subtype and properties.
local acquirement_classes = {
    classes.OBJ_WEAPONS,
    classes.OBJ_ARMOUR,
    classes.OBJ_JEWELLERY,
    classes.OBJ_BOOKS,
    classes.OBJ_STAVES,
    classes.OBJ_WANDS,
    classes.OBJ_MISCELLANY,
    classes.OBJ_GOLD,
    classes.OBJ_MISSILES,
}

-- The source can gift a plain item even when it would make a poor
-- acquirement offer. Use ordinary class weights rather than acquirement's
-- player-specific class picker for this event.
local function random_item(ctx, player, severity)
    if not gifts.safe_floor(ctx, player) then
        return nil
    end

    local position = ctx:get(player, component.POSITION)
    local rolled = generation.roll(ctx, {
        depth = math.max(1, severity * 3),
        quality = quality.ORDINARY,
        purpose = purpose.GOD_GIFT,
        god_id = gods.XOM,
        site = "Xom random item",
    })

    return generation.create(ctx, rolled, {
        position = {
            level_id = position.level_id,
            x = position.x,
            y = position.y,
        },
    })
end

-- The shared offer owner handles anatomy, seen armour, brand quality, and
-- artefact claims. Miscellany and gold have no acquirement subtype picker,
-- so their source class still uses the common item generator directly.
local function acquired_item(ctx, player, stream)
    if not gifts.safe_floor(ctx, player) then
        return nil
    end

    local index = ctx:random(stream, #acquirement_classes) + 1
    local class_id = acquirement_classes[index]

    if class_id ~= classes.OBJ_MISCELLANY and
        class_id ~= classes.OBJ_GOLD then
        return gifts.grant(ctx, player, class_id, gods.XOM)
    end

    local position = ctx:get(player, component.POSITION)
    local rolled = generation.roll(ctx, {
        class_id = class_id,
        depth = math.max(1, ctx:level_depth(position.level_id)),
        quality = quality.GIFT,
        purpose = purpose.GOD_GIFT,
        god_id = gods.XOM,
        site = "Xom acquirement",
    })

    return generation.create(ctx, rolled, {
        position = {
            level_id = position.level_id,
            x = position.x,
            y = position.y,
        },
    })
end

-- Announce only a gift actually placed. A molten floor or an incompatible
-- acquisition can reject the action without inventing an item record.
function effect.apply(ctx, player, event_id, severity, request)
    local stream = request and request.stream or streams.RELIGION
    local item

    if event_id == events.GOOD_RANDOM_ITEM then
        item = random_item(ctx, player, severity)
    elseif event_id == events.GOOD_ACQUIREMENT then
        item = acquired_item(ctx, player, stream)
    else
        error("item effect received another Xom event")
    end

    if item then
        ctx:emit(channels.RELIGION,
            "Xom presents you with a gift!")
    end

    return item
end

return effect
