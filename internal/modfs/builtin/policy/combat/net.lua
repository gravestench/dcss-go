local catalog = require("policy.catalog")

local net = {}

local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

function net.can_hold(definition)
    -- traps.cc:247-286 excludes giants, stationary monsters, and ghosts.
    return definition.size_id ~= "SIZE_GIANT" and
        not has_flag(definition.flags, "M_STATIONARY") and
        not has_flag(definition.flags, "M_INSUBSTANTIAL")
end

function net.catch(ctx, monster, net_item, definition)
    if not net.can_hold(definition) or ctx:has(monster, "projectile.held") then
        return false
    end

    ctx:add(net_item, "projectile.net", {
        durability = 0,
    })
    ctx:add(monster, "projectile.held", {
        net = net_item,
        newly_trapped = true,
    })
    ctx:emit("combat", "The " .. definition.name .. " is caught in the net!")

    return true
end

function net.struggle(ctx, monster, held)
    local actor = ctx:get(monster, "core.actor")
    local definition = catalog.get("monsters", actor.kind_id)
    local net_item = held.net
    local durability = ctx:get(net_item, "projectile.net")

    if not durability then
        error("held monster has no trapping net")
    end

    -- mon-act.cc:2001-2017 gives the newly caught monster one action before
    -- its first struggle. A struggle consumes the whole monster action.
    if held.newly_trapped then
        held.newly_trapped = false
        ctx:set(monster, "projectile.held", held)

        return
    end

    ctx:emit("combat", "The " .. definition.name .. " struggles against the net.")

    local damage = 1 + ctx:random("ai", 2)
    local scaled = damage * actor.speed
    local whole = math.floor(scaled / 10)

    if scaled % 10 > 0 and ctx:random("ai", 10) < scaled % 10 then
        whole = whole + 1
    end

    durability.durability = durability.durability - whole

    if durability.durability < -7 then
        -- NET_MIN_DURABILITY is -7 in traps.h:17.
        ctx:remove(monster, "projectile.held")
        ctx:destroy(net_item)
        ctx:emit("combat", "The net rips apart, and the " ..
            definition.name .. " comes free!")

        return
    end

    ctx:set(net_item, "projectile.net", durability)
end

function net.validate(ctx, monster, position)
    local held = ctx:get(monster, "projectile.held")

    if not held then
        return
    end

    local net_item = held.net
    local item = ctx:get(net_item, "core.item")
    local net_position = ctx:get(net_item, "core.position")
    local durability = ctx:get(net_item, "projectile.net")

    if not item or item.kind_id ~= "MI_THROWING_NET" or
        item.quantity ~= 1 or not net_position or not durability or
        net_position.level_id ~= position.level_id or
        net_position.x ~= position.x or net_position.y ~= position.y or
        durability.durability < -7 or durability.durability > 0 then
        error("monster " .. ctx:id(monster) .. " has an invalid trapping net")
    end
end

function net.release(ctx, monster)
    local held = ctx:get(monster, "projectile.held")

    if not held then
        return
    end

    local net_item = held.net
    local durability = ctx:get(net_item, "projectile.net")

    if not durability then
        error("held monster has no trapping net")
    end

    -- traps.cc:920-938 mulches a damaged net when its captive leaves it.
    local damage = -durability.durability
    local mulched = damage > 0 and ctx:random("ai", 9) < damage
    ctx:remove(monster, "projectile.held")

    if mulched then
        ctx:destroy(net_item)
    else
        ctx:remove(net_item, "projectile.net")
    end
end

return net
