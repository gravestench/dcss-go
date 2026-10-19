local component = require("constants.component")

local status = {}

local fields = {
    "corona_aut",
    "anchor_aut",
    "poison_vuln_aut",
    "sap_aut",
    "no_cast_aut",
}

local function active(ctx, actor, field)
    local state = ctx:get(actor, component.HEX_STATUS)

    return state ~= nil and state[field] > 0
end

local function extend(ctx, actor, field, added, maximum)
    local state = ctx:get(actor, component.HEX_STATUS)
    local existed = state ~= nil

    state = state or {
        corona_aut = 0,
        anchor_aut = 0,
        poison_vuln_aut = 0,
        sap_aut = 0,
        no_cast_aut = 0,
    }

    state[field] = math.min(maximum, state[field] + added)

    if existed then
        ctx:set(actor, component.HEX_STATUS, state)
    else
        ctx:add(actor, component.HEX_STATUS, state)
    end
end

function status.backlit(ctx, actor)
    return active(ctx, actor, "corona_aut")
end

function status.anchored(ctx, actor)
    return active(ctx, actor, "anchor_aut")
end

function status.poison_vulnerable(ctx, actor)
    return active(ctx, actor, "poison_vuln_aut")
end

function status.sapped(ctx, actor)
    return active(ctx, actor, "sap_aut")
end

function status.cannot_cast(ctx, actor)
    return active(ctx, actor, "no_cast_aut")
end

function status.corona(ctx, actor, duration_aut)
    extend(ctx, actor, "corona_aut", duration_aut, 2500)
end

function status.anchor(ctx, actor, duration_aut)
    extend(ctx, actor, "anchor_aut", duration_aut, 500)
end

function status.poison_vulnerability(ctx, actor, duration_aut)
    extend(ctx, actor, "poison_vuln_aut", duration_aut, 500)
end

function status.sap_magic(ctx, actor, duration_aut)
    extend(ctx, actor, "sap_aut", duration_aut, 500)
end

function status.no_cast(ctx, actor, duration_aut)
    extend(ctx, actor, "no_cast_aut", duration_aut, 500)
end

function status.tick(ctx, actor, elapsed)
    local state = ctx:get(actor, component.HEX_STATUS)

    if not state or elapsed <= 0 then
        return
    end

    local remaining = false

    for _, field in ipairs(fields) do
        state[field] = math.max(0, state[field] - elapsed)
        remaining = remaining or state[field] > 0
    end

    if remaining then
        ctx:set(actor, component.HEX_STATUS, state)
    else
        ctx:remove(actor, component.HEX_STATUS)
    end
end

return status
