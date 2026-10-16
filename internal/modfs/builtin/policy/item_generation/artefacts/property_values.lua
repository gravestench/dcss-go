local streams = require("constants.rng_streams")
local values = {}
local kinds = require("constants.artefact_value_kinds")

local function draw(ctx, bound)
    return ctx:random(streams.ITEM_GENERATION, bound)
end

function values.good(ctx, kind)
    if kind == kinds.STAT then
        return 1 + draw(ctx, 3)
    elseif kind == kinds.RESISTANCE or kind == kinds.BOOLEAN then
        return 1
    elseif kind == kinds.HPMP then
        return 9
    elseif kind == kinds.SLAYING then
        return 2 + draw(ctx, 2)
    end

    error("unknown good artefact property value " .. tostring(kind))
end

function values.bad(ctx, kind)
    if kind == kinds.STAT then
        return -2 - draw(ctx, 4)
    elseif kind == kinds.RESISTANCE then
        return -1
    elseif kind == kinds.HPMP then
        return -9
    elseif kind == kinds.SLAYING then
        return -2 - draw(ctx, 5)
    elseif kind == kinds.NOISE then
        return 2
    elseif kind == kinds.ANGRY then
        return 20
    elseif kind == kinds.BOOLEAN then
        return 1
    end

    error("unknown bad artefact property value " .. tostring(kind))
end

return values
