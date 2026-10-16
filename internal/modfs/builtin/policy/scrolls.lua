local catalog = require("policy.catalog")
local classes = require("ids.object_classes")

local scrolls = {}
local effects = {}

function scrolls.register(id, effect)
    local kind = catalog.get("items", id)

    if kind.class ~= classes.OBJ_SCROLLS then
        error("scroll effect " .. id .. " is not a scroll item")
    end

    if type(effect) ~= "table" or
        type(effect.prepare) ~= "function" or
        type(effect.apply) ~= "function" then
        error("scroll effect " .. id .. " needs prepare and apply")
    end

    if effects[id] then
        error("duplicate scroll effect " .. id)
    end

    effects[id] = effect
end

function scrolls.get(id)
    return effects[id]
end

function scrolls.validate()
    for _, kind in ipairs(catalog.all("items")) do
        if kind.class == classes.OBJ_SCROLLS and
            not kind.explicitly_removed and
            not effects[kind.id] then
            local origin = register.origin("items", kind.id)

            error("scroll " .. kind.id .. " from " .. origin ..
                " has no effect")
        end
    end
end

return scrolls
