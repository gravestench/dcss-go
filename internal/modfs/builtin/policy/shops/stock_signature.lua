local component = require("constants.component")

local stock_signature = {}

local tracked = {
    component.ITEM,
    component.ITEM_IDENTIFICATION,
    component.ITEM_ARTEFACT,
    component.ITEM_RANDOM_BOOK,
    component.ITEM_MANUAL,
}

local function scalar(value)
    local kind = type(value)

    if kind == "nil" then
        return "n"
    elseif kind == "boolean" then
        return value and "b1" or "b0"
    elseif kind == "number" then
        return "d" .. string.format("%.17g", value) .. ";"
    elseif kind == "string" then
        return "s" .. #value .. ":" .. value
    end

    error("shop stock contains an unsupported field type " .. kind)
end

local function key_order(left, right)
    return tostring(left) < tostring(right)
end

local function encode(value)
    if type(value) ~= "table" then
        return scalar(value)
    end

    local keys = {}

    for key in pairs(value) do
        keys[#keys + 1] = key
    end

    table.sort(keys, key_order)

    local parts = { "t", tostring(#keys), ":" }

    for _, key in ipairs(keys) do
        parts[#parts + 1] = encode(key)
        parts[#parts + 1] = encode(value[key])
    end

    return table.concat(parts)
end

function stock_signature.of(ctx, entity)
    local parts = {}

    for _, id in ipairs(tracked) do
        parts[#parts + 1] = encode(ctx:get(entity, id))
    end

    return table.concat(parts)
end

return stock_signature
