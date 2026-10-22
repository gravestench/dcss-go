local items = require("policy.inventory.items")
local identification = require("policy.items.identification")
local wallet = require("policy.shops.wallet")
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local runes = require("policy.character.runes")
local endgame = require("policy.character.endgame")
local component = require("constants.component")

local system = {}

-- Theory of operation: Floor gold becomes wallet value while item entities become carried stacks before drop handling.
-- Pickup handles gold through the wallet and items through carried components before drop actions.
function system.update(ctx, actor)
    local intent = ctx:get(actor, "core.intent")

    if not intent or intent.kind ~= 3 then
        return
    end

    local position = ctx:get(actor, "core.position")

    if not position then
        error("pickup actor " .. ctx:id(actor) .. " has no position")
    end

    for _, entity in ipairs(items.at(ctx, position)) do
        if not ctx:has(entity, "core.corpse") then
            local item = ctx:get(entity, "core.item")
            local name = identification.name(ctx, ctx:player(), entity)
            local definition = catalog.get("items", item.kind_id)

            -- A source mimic presents the authored item's appearance until
            -- interaction. It vanishes before gold, rune, or stack handling
            -- can grant the player anything from that false item.
            if ctx:has(entity, component.VAULT_ITEM_MIMIC) then
                ctx:destroy(entity)
                ctx:emit("pickup", "The " .. name .. " was a mimic!")

                return
            end

            if definition.class == classes.OBJ_GOLD then
                local amount = wallet.pickup(ctx, actor, entity)

                if amount > 0 then
                    ctx:emit("pickup", "You pick up " .. amount .. " gold pieces.")
                end

                return
            end

            -- Source runes become permanent character progress on pickup;
            -- their floor entity does not turn into an inventory stack.
            if definition.class == classes.OBJ_RUNES then
                runes.collect(ctx, actor, item.kind_id)
                ctx:destroy(entity)
                ctx:emit("pickup", "You pick up " .. items.phrase(name, 1) .. ".")

                return
            end

            -- The Orb is chapter progress in source DCSS, not a carried
            -- stack. Its live floor entity is consumed exactly once.
            if item.kind_id == item_ids.ORB_ZOT and
                definition.class == classes.OBJ_ORBS then
                endgame.take_orb(ctx, actor, item, position)
                ctx:destroy(entity)

                return
            end

            local stack = items.carried_stack(ctx, actor, entity)

            if stack then
                local carried = ctx:get(stack, "core.item")
                carried.quantity = carried.quantity + item.quantity
                ctx:set(stack, "core.item", carried)
                ctx:destroy(entity)
            else
                ctx:remove(entity, "core.position")
                ctx:add(entity, "core.carried_by", { holder = actor })
            end

            ctx:emit("pickup", "You pick up " .. items.phrase(name, item.quantity) .. ".")

            return
        end
    end

    error("pickup actor " .. ctx:id(actor) .. " has no floor item")
end

register.system({
    id = "item.pickup",
    scope = "active",
    query = {},
    before = { "item.drop" },
    update = system.update,
})

return system
