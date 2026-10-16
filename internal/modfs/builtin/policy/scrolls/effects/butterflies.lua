-- Source: spl-summoning.cc:summon_butterflies creates 10-20 friendly allies.
local allies = require("policy.character.allies")
local categories = require("constants.catalog")
local component = require("constants.component")
local item_ids = require("ids.items")
local monsters = require("ids.monsters")
local scrolls = require("policy.scrolls")
local summons = require("policy.magic.effects.summons.common")

local effect = {}
local RADIUS = 4

local function open_cells(ctx, position)
    local cells = {}

    for y = position.y - RADIUS, position.y + RADIUS do
        for x = position.x - RADIUS, position.x + RADIUS do
            if ctx:walkable(position.level_id, x, y) and
                not ctx:actor_at(position.level_id, x, y) then
                cells[#cells + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return cells
end

function effect.prepare(ctx, player, request)
    if request.known and allies.forbidden(ctx, player) then
        return {
            message = "You cannot coerce anything to answer your summons.",
        }
    end

    return nil
end

function effect.apply(ctx, player)
    if allies.forbidden(ctx, player) then
        ctx:emit("read", "Nothing happens.")

        return
    end

    local position = ctx:get(player, component.POSITION)
    local cells = open_cells(ctx, position)
    local attempts = 10 + ctx:random("spell", 11)
    local created = 0

    for _ = 1, attempts do
        if #cells == 0 then
            break
        end

        local index = 1 + ctx:random("spell", #cells)
        local cell = table.remove(cells, index)
        local summon = summons.spawn(ctx, player,
            item_ids.SCR_BUTTERFLIES, monsters.MONS_BUTTERFLY,
            3, 25, {
                source_category = categories.ITEMS,
                exact = cell,
            })

        if summon then
            created = created + 1
        end
    end

    if created == 0 then
        ctx:emit("read", "Nothing happens.")
    else
        ctx:emit("read", "You hear the tinkle of a tiny bell.")
    end
end

scrolls.register(item_ids.SCR_BUTTERFLIES, effect)

return effect
