-- Example: A malformed D:1- depth expression reports its DES path and source line.
local categories = require("constants.catalog")
local chance_units = require("constants.vault_chance")
local specifiers = require("policy.generation.vaults.specifiers")

local depth = {}

-- Attach DES path, line, and vault ID to malformed depth-rule errors.
local function fail(site, text)
    error(string.format("%s:%d: vault %s: %s",
        site.path, site.line, site.id, text))
end

-- Normalize whitespace before interpreting branch and range tokens.
local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

-- Match rules against branch abbreviations stored in the registered branch catalog.
local function branch_name(branch_id)
    local definition = register.get(categories.BRANCHES, branch_id)

    return definition.abbreviation
end

-- Parse branch exclusions and bottom-of-branch markers before numeric depth ranges.
local function depth_rule(token, site)
    local excluded = token:sub(1, 1) == "!"

    if excluded then
        token = token:sub(2)
    end

    local branch, range = token:match("^([A-Za-z]+):(.+)$")

    if not branch then
        branch = token:match("^([A-Za-z]+)$")
    end

    if not branch then
        fail(site, "invalid DEPTH term " .. token)
    end

    local first
    local last
    local bottom = false

    if range then
        if range == "$" then
            bottom = true
        else
            local low, high = range:match("^(%d+)%-(%d+)$")

            if low then
                first = tonumber(low)
                last = tonumber(high)
            else
                low = range:match("^(%d+)%-$")

                if low then
                    first = tonumber(low)
                else
                    low = range:match("^(%d+)$")

                    if not low then
                        fail(site, "invalid DEPTH range " .. range)
                    end

                    first = tonumber(low)
                    last = first
                end
            end
        end
    end

    if first and (first < 1 or (last and last < first)) then
        fail(site, "invalid DEPTH range " .. range)
    end

    return {
        branch = branch,
        excluded = excluded,
        first = first,
        last = last,
        bottom = bottom,
    }
end

-- Keep rule order from the DES line because a later exclusion may veto an inclusion.
function depth.parse_rules(argument, site)
    local rules = {}

    for token in (argument .. ","):gmatch("(.-),") do
        token = trim(token)

        if token ~= "" then
            rules[#rules + 1] = depth_rule(token, site)
        end
    end

    if #rules == 0 then
        fail(site, "DEPTH has no terms")
    end

    return rules
end

-- Convert source percentages and raw integers into the source's 10,000-point
-- roll. Decimal percents such as 0.5% are exact on that scale.
local function chance_roll(number, percent, site, argument)
    local value = tonumber(number)

    if percent == "%" then
        value = value and value * chance_units.PERCENT
    end

    if not value or value < 0 or value > chance_units.ROLL or
        value ~= math.floor(value) then
        fail(site, "invalid CHANCE " .. argument)
    end

    return value
end

-- Parse each top-level clause separately; commas inside a depth group are
-- alternatives for one chance, not separate chances.
function depth.parse_chance(argument, site)
    local clauses = {}

    for _, text in ipairs(specifiers.split(argument, site)) do
        local number, percent, group = text:match(
            "^%s*([%d%.]+)(%%?)%s*(%b())%s*$")

        if not number then
            number, percent = text:match("^%s*([%d%.]+)(%%?)%s*$")
        end

        if not number then
            fail(site, "invalid CHANCE " .. text)
        end

        local clause = {
            chance = chance_roll(number, percent, site, text),
        }

        if group then
            clause.rules = depth.parse_rules(group:sub(2, -2), site)
        end

        clauses[#clauses + 1] = clause
    end

    return clauses
end

-- A dollar depth token compares to the branch bottom, not an absolute Dungeon floor.
local function matches(rule, name, local_depth, branch_bottom)
    if rule.branch ~= name then
        return false
    end

    if rule.bottom then
        return local_depth ~= nil and local_depth == branch_bottom
    end

    if local_depth == nil and (rule.first or rule.last) then
        return false
    end

    return (not rule.first or local_depth >= rule.first) and
        (not rule.last or local_depth <= rule.last)
end

-- Weight and chance clauses share the same branch/depth range semantics as
-- DEPTH itself, so they must not carry separate interpretations.
function depth.matches_rule(rule, branch_id, local_depth, branch_bottom)
    return matches(rule, branch_name(branch_id), local_depth, branch_bottom)
end

-- An excluded matching rule wins even if another range includes the same floor.
function depth.eligible(vault, branch_id, local_depth, branch_bottom)
    if #vault.depths == 0 then
        return true
    end

    local name = branch_name(branch_id)
    local included = false

    for _, rule in ipairs(vault.depths) do
        if matches(rule, name, local_depth, branch_bottom) then
            if rule.excluded then
                return false
            end

            included = true
        end
    end

    return included
end

-- Specific branch/depth clauses override a bare fallback regardless of
-- declaration order. Both return source roll units, not rounded percents.
function depth.chance(vault, branch_id, local_depth, branch_bottom)
    if #vault.chances == 0 then
        return chance_units.ROLL
    end

    if local_depth == nil then
        error("vault CHANCE selection requires local depth")
    end

    local name = branch_name(branch_id)
    local fallback = 0
    for _, row in ipairs(vault.chances) do
        if not row.rules then
            fallback = row.chance
        else
            for _, rule in ipairs(row.rules) do
                if matches(rule, name, local_depth, branch_bottom) then
                    return row.chance
                end
            end
        end
    end

    return fallback
end

return depth
