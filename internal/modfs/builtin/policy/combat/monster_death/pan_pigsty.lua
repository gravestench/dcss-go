-- Theory of operation: the source swineherd's MonPropsMarker calls Lua on
-- death to raise one iron grate. The actor's saved vault origin points to
-- its original marker cell even if it moved, and the saved gate marker
-- identifies the affected terrain after map rotation and save/restore.
local channels = require("constants.message_channels")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local pigsty = require("constants.pan_pigsty")
local terrain = require("constants.terrain")

local policy = {}

-- Find the first source gate on the actor's floor in stable row order.
-- Keeping this lookup in the level avoids a second location in actor state.
local function gate(ctx, level_id)
    local width, height = ctx:level_size(level_id)

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if ctx:marker_property(level_id, x, y,
                pigsty.GATE_PROPERTY) == pigsty.GATE_VALUE then
                return x, y
            end
        end
    end

    return nil, nil
end

-- The marker on the spawn cell, not current monster species or position,
-- determines whether this is the particular swineherd from the source MAP.
local function marked_swineherd(ctx, actor)
    local origin = ctx:get(actor, component.VAULT_ORIGIN)

    if not origin or origin.vault_id ~= pigsty.MAP_ID then
        return nil
    end

    local marker = ctx:marker_property(origin.level_id,
        origin.spawn_x, origin.spawn_y, pigsty.SWINEHERD_PROPERTY)

    if marker ~= pigsty.SWINEHERD_VALUE then
        return nil
    end

    return origin
end

-- Open the marked grate once. A missing marker reports the source error;
-- an already opened or transformed grate has no second effect.
function policy.on_death(ctx, actor)
    local origin = marked_swineherd(ctx, actor)

    if not origin then
        return false
    end

    local x, y = gate(ctx, origin.level_id)

    if not x then
        ctx:emit(channels.VAULT, pigsty.MISSING_GATE)

        return false
    end

    if ctx:cell(origin.level_id, x, y) ~= terrain.DNGN_GRATE then
        return false
    end

    ctx:set_cell(origin.level_id, x, y, terrain.DNGN_FLOOR)

    local player = ctx:get(ctx:player(), component.POSITION)
    local visible = player and player.level_id == origin.level_id and
        ctx:visible(origin.level_id, player.x, player.y, 7, x, y)
    local message = visible and pigsty.VISIBLE_OPEN or pigsty.HEARD_OPEN

    ctx:emit(channels.VAULT, message)

    return false
end

death_hooks.add("pan.pigsty.swineherd", policy.on_death)

return policy
