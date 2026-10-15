-- One owner places miasma from corpse rot and mutation retaliation.
local component = require("constants.component")
local cloud = require("policy.magic.effects.zaps.cloud")

local miasma = {}

function miasma.occupied(ctx, level_id, x, y)
    if cloud.at(ctx, level_id, x, y) then
        return true
    end

    for _, marker in ipairs(ctx:query({ component.MIASMA_CLOUD })) do
        local state = ctx:get(marker, component.MIASMA_CLOUD)

        if state.level_id == level_id and state.x == x and state.y == y and
            state.expires_aut > ctx:aut() then
            return true
        end
    end

    return false
end

function miasma.available(ctx, level_id, x, y)
    return ctx:walkable(level_id, x, y) and
        not miasma.occupied(ctx, level_id, x, y)
end

function miasma.place(ctx, level_id, x, y, duration_aut)
    if duration_aut <= 0 or not miasma.available(ctx, level_id, x, y) then
        return nil
    end

    local marker = ctx:create()

    ctx:add(marker, component.MIASMA_CLOUD, {
        level_id = level_id,
        x = x,
        y = y,
        expires_aut = ctx:aut() + duration_aut,
    })

    return marker
end

return miasma
