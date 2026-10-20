-- DES WEIGHT clauses choose the first matching depth range, then the default.
local categories = require("constants.catalog")
local depth = require("policy.generation.vaults.depth")
local specifiers = require("policy.generation.vaults.specifiers")

local weight = {}

-- Attach the source site because malformed content must fail before a rare
-- map reaches a live selector.
local function fail(site, detail)
    error(string.format("%s:%d: vault %s: %s",
        site.path, site.line, site.id, detail))
end

-- Reject branch typos at catalog load, while still allowing mods to add a
-- branch through the same effective branch catalog.
local function known_branches()
    local names = {}

    for _, id in ipairs(register.ids(categories.BRANCHES)) do
        local branch = register.get(categories.BRANCHES, id)

        names[branch.abbreviation] = true
    end

    return names
end

-- Keep source range order: map_def's depth_ranges returns the first matching
-- range, even when another range overlaps it later in the declaration.
function weight.parse(argument, site)
    local parsed = {
        ranges = {},
    }
    local known = known_branches()
    local seen = {}

    for _, clause in ipairs(specifiers.split(argument, site)) do
        local number, group = clause:match("^%s*(%d+)%s*(%b())%s*$")

        if not number then
            number = clause:match("^%s*(%d+)%s*$")
        end

        if not number then
            fail(site, "invalid WEIGHT clause " .. clause)
        end

        local value = tonumber(number)

        if group then
            local rules = depth.parse_rules(group:sub(2, -2), site)

            for _, rule in ipairs(rules) do
                if rule.branch ~= "*" and not known[rule.branch] then
                    fail(site, "invalid WEIGHT branch " .. rule.branch)
                end

                local key = table.concat({
                    rule.branch,
                    tostring(rule.first),
                    tostring(rule.last),
                    tostring(rule.bottom),
                }, ":")

                if seen[key] then
                    fail(site, "repeated WEIGHT range " .. rule.branch)
                end

                seen[key] = true
            end

            parsed.ranges[#parsed.ranges + 1] = {
                value = value,
                rules = rules,
            }
        else
            if parsed.default ~= nil then
                fail(site, "repeated default WEIGHT")
            end

            parsed.default = value
        end
    end

    return parsed
end

-- Resolve source ranges against the current branch and depth. A map with no
-- default weight is disabled outside its listed ranges.
function weight.for_branch(vault, branch_id, local_depth, branch_bottom)
    local rules = vault.weights

    if not rules then
        return vault.weight or 0
    end

    for _, range in ipairs(rules.ranges) do
        for _, rule in ipairs(range.rules) do
            if depth.matches_rule(rule, branch_id,
                local_depth, branch_bottom) then
                return range.value
            end
        end
    end

    return rules.default or 0
end

return weight
