-- Example: A shop item token trims spaces before quantity and stock flags are parsed.
local ids = require("ids.shops")
local item_specs = require("policy.generation.vaults.specs.item")

local shop_spec = {}

local kinds = {
    ["weapon shop"] = ids.SHOP_WEAPON,
    ["armour shop"] = ids.SHOP_ARMOUR,
    ["antique weapon shop"] = ids.SHOP_WEAPON_ANTIQUE,
    ["antique armour shop"] = ids.SHOP_ARMOUR_ANTIQUE,
    ["antiques shop"] = ids.SHOP_GENERAL_ANTIQUE,
    ["jewellery shop"] = ids.SHOP_JEWELLERY,
    ["book shop"] = ids.SHOP_BOOK,
    ["distillery shop"] = ids.SHOP_DISTILLERY,
    ["scroll shop"] = ids.SHOP_SCROLL,
    ["general shop"] = ids.SHOP_GENERAL,
    ["any shop"] = ids.SHOP_RANDOM,
}

-- Strip surrounding DES whitespace before parsing shop tokens.
local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

-- Keep source site and expression in malformed shop-stock errors.
local function fail(site, expression, detail)
    error(string.format("%s:%d: vault %s: shop %s: %s",
        site.path, site.line or 0, site.vault_id,
        expression, detail))
end

-- The outer vertical bar separates stock items without splitting commas inside an item name.
local function stock_items(expression, site)
    local items = {}

    if not expression or trim(expression) == "" then
        return items
    end

    for part in (expression .. "|"):gmatch("(.-)|") do
        part = trim(part)

        if part == "" then
            fail(site, expression, "empty stock item")
        end

        items[#items + 1] = item_specs.term(part, site)
    end

    return items
end

-- Each slash alternative owns its stock, name, count, greed, and selection weight.
local function alternative(text, items, site)
    -- Source keyed features may choose bare floor instead of a shop.
    -- Keep its ordinary weight in the same draw and create no stock.
    if text == "." then
        if #items > 0 then
            fail(site, text, "floor alternative cannot carry shop stock")
        end

        return {
            weight = 10,
            items = {},
            site = site,
        }
    end

    local kind, options = text:match("^(.- shop)%s*(.*)$")
    local id = kinds[kind]

    if not id then
        fail(site, text, "unknown shop kind")
    end

    local spec = {
        kind_id = id,
        weight = 10,
        items = items,
        site = site,
    }

    for token in options:gmatch("%S+") do
        local key, value = token:match("^([%w_]+):(.*)$")

        if token == "use_all" then
            spec.use_all = true
        elseif key == "name" then
            spec.name = value:gsub("_", " ")
        elseif key == "type" then
            spec.type_name = value:gsub("_", " ")
        elseif key == "suffix" then
            spec.suffix = value:gsub("_", " ")
        elseif key == "count" then
            spec.count = tonumber(value)

            if not spec.count or spec.count < 1 or
                spec.count > 20 or spec.count % 1 ~= 0 then
                fail(site, text, "count must be between 1 and 20")
            end
        elseif key == "greed" then
            spec.greed = tonumber(value)

            if not spec.greed or spec.greed < 0 or
                spec.greed % 1 ~= 0 then
                fail(site, text, "greed must be a nonnegative integer")
            end
        elseif key == "w" then
            spec.weight = tonumber(value)

            if not spec.weight or spec.weight < 1 or
                spec.weight % 1 ~= 0 then
                fail(site, text, "weight must be a positive integer")
            end
        else
            fail(site, text, "unknown shop option " .. token)
        end
    end

    return spec
end

-- Recognize only catalogued shop prefixes before interpreting a KFEAT as stock.
function shop_spec.is_shop(expression)
    local kind = expression:match("^%s*(.- shop)")

    return kind ~= nil and kinds[kind] ~= nil
end

-- Validate every slash alternative before a shop can be selected from its weighted list.
function shop_spec.parse(expression, site)
    local descriptor, stock = expression:match("^(.-)%s*;%s*(.*)$")

    if not descriptor then
        descriptor = expression
    end

    local items = stock_items(stock, site)
    local alternatives = {}

    for part in (descriptor .. "/"):gmatch("(.-)/") do
        alternatives[#alternatives + 1] =
            alternative(trim(part), items, site)
    end

    return alternatives
end

-- Consume one weighted draw after validation has established positive candidate weights.
-- Selection draws only after parsing has assigned a positive weight to each alternative.
function shop_spec.choose(random, alternatives)
    local total = 0

    for _, candidate in ipairs(alternatives) do
        total = total + candidate.weight
    end

    local draw = random:roll(total)

    for _, candidate in ipairs(alternatives) do
        if draw < candidate.weight then
            return candidate
        end

        draw = draw - candidate.weight
    end

    error("shop alternative selection exceeded its weight total")
end

return shop_spec
