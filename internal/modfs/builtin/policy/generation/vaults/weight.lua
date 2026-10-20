-- DES WEIGHT lines may have a default and branch-specific overrides. Keep
-- these rules beside the source map instead of copying them into selectors.
local categories = require("constants.catalog")

local weight = {}

-- Include the source site because a bad mod weight must fail at catalog
-- loading, before a rare layout happens to be drawn during play.
local function fail(site, detail)
    error(string.format("%s:%d: vault %s: %s",
        site.path, site.line, site.id, detail))
end

-- Resolve the names actually registered by the effective ruleset. A mod
-- branch may add a new abbreviation without changing this parser.
local function branch_names()
    local names = {}

    for _, id in ipairs(register.ids(categories.BRANCHES)) do
        local branch = register.get(categories.BRANCHES, id)

        names[branch.abbreviation] = true
    end

    return names
end

-- Parse one default or one branch-qualified integer per comma-separated
-- clause. A missing default means unlisted branches have zero weight.
function weight.parse(argument, site)
    local rules = {
        branches = {},
    }
    local known = branch_names()
    local clauses = 0

    for text in (argument .. ","):gmatch("(.-),") do
        local clause = text:match("^%s*(.-)%s*$")

        if clause ~= "" then
            local number, branch = clause:match("^(%d+)%s*%(([A-Za-z]+)%)$")

            if number then
                if not known[branch] or rules.branches[branch] ~= nil then
                    fail(site, "invalid or repeated WEIGHT branch " .. branch)
                end

                rules.branches[branch] = tonumber(number)
            else
                number = clause:match("^(%d+)$")

                if not number or rules.default ~= nil then
                    fail(site, "invalid or repeated WEIGHT clause " .. clause)
                end

                rules.default = tonumber(number)
            end

            clauses = clauses + 1
        end
    end

    if clauses == 0 then
        fail(site, "WEIGHT has no clauses")
    end

    return rules
end

-- A branch clause wins over the default; otherwise an omitted default is
-- zero so a layout cannot silently appear in an unrelated branch.
function weight.for_branch(vault, branch_id)
    local rules = vault.weights

    if not rules then
        return vault.weight or 0
    end

    local branch = register.get(categories.BRANCHES, branch_id)
    local specific = rules.branches[branch.abbreviation]

    if specific ~= nil then
        return specific
    end

    return rules.default or 0
end

return weight
