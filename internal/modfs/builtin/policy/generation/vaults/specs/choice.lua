-- DES alternatives use reservoir selection, not a single weighted draw.
-- Source: mapdef.cc mons_list::pick_monster and item_list::pick_item.
local choice = {}

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function source_site(site, expression)
    local path = site and site.path or "unknown vault"
    local line = site and site.line or 0
    local vault = site and site.vault_id or "unknown"
    local directive = site and site.directive or "unknown directive"
    local glyph = site and site.glyph or "?"

    return string.format("%s:%s: vault %s: %s glyph %s: %s",
        path, line, vault, directive, glyph, expression)
end

function choice.fail(site, expression, detail)
    error(source_site(site, expression) .. ": " .. detail, 3)
end

function choice.slots(expression, site, parse_term)
    if type(expression) ~= "string" or trim(expression) == "" then
        choice.fail(site, tostring(expression), "empty expression")
    end

    local slots = {}

    for slot_text in (expression .. ","):gmatch("(.-),") do
        local alternatives = {}

        for term_text in (slot_text .. "/"):gmatch("(.-)/") do
            local term = trim(term_text)

            if term == "" then
                choice.fail(site, expression, "empty alternative")
            end

            alternatives[#alternatives + 1] = parse_term(term, expression, site)
        end

        slots[#slots + 1] = alternatives
    end

    return slots
end

function choice.pick(random, alternatives)
    local total = 0
    local selected

    for _, alternative in ipairs(alternatives) do
        total = total + alternative.weight

        if random:roll(total) < alternative.weight then
            selected = alternative
        end
    end

    return selected
end

return choice
