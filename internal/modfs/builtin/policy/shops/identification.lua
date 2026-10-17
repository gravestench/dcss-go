local appearances = require("policy.items.appearances")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local items = require("policy.items.identification")

local identification = {}

local equipment = {
    [classes.OBJ_WEAPONS] = true,
    [classes.OBJ_ARMOUR] = true,
    [classes.OBJ_JEWELLERY] = true,
    [classes.OBJ_STAVES] = true,
}

function identification.stock(ctx, entity, kind)
    local manual = kind.id == ids.BOOK_MANUAL
    local fields = {
        type = appearances.pool(kind) ~= nil or manual,
        pluses = equipment[kind.class] or manual,
        properties = equipment[kind.class] or manual,
    }

    if fields.type or fields.pluses or fields.properties then
        items.reveal_item(ctx, entity, fields)
    end
end

function identification.purchase(ctx, player, entity, kind)
    items.reveal_type(ctx, player, entity)
    identification.stock(ctx, entity, kind)
end

return identification
