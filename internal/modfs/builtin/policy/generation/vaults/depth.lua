-- Example: A malformed D:1- depth expression reports its DES path and source line.
local categories = require("constants.catalog")

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

-- Validate branch-qualified percentages at parse time, before weighted vault selection.
function depth.parse_chance(argument, site)
    local percent, branches = argument:match("^(%d+)%%%s*%((.-)%)$")
    local value = tonumber(percent)

    if not value or value < 0 or value > 100 then
        fail(site, "invalid CHANCE " .. argument)
    end

    local names = {}

    for branch in (branches .. ","):gmatch("(.-),") do
        branch = trim(branch)

        if not branch:match("^[A-Za-z]+$") then
            fail(site, "invalid CHANCE branch " .. branch)
        end

        names[#names + 1] = branch
    end

    if #names == 0 then
        fail(site, "CHANCE has no branches")
    end

    return {
        percent = value,
        branches = names,
    }
end

-- A dollar depth token compares to the branch bottom, not an absolute Dungeon floor.
local function matches(rule, name, local_depth, branch_bottom)
    if rule.branch ~= name then
        return false
    end

    if rule.bottom then
        return local_depth == branch_bottom
    end

    return (not rule.first or local_depth >= rule.first) and
        (not rule.last or local_depth <= rule.last)
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

-- Branch-specific CHANCE rows override the default; no matching branch means zero chance.
function depth.chance(vault, branch_id)
    if #vault.chances == 0 then
        return 100
    end

    local name = branch_name(branch_id)

    for _, row in ipairs(vault.chances) do
        for _, branch in ipairs(row.branches) do
            if branch == name then
                return row.percent
            end
        end
    end

    return 0
end

return depth
