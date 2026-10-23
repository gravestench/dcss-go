-- Theory of operation: conduct descriptions are a projection of the
-- effective god rule module. Mods replace that module once; both gameplay
-- and the UI read its metadata without a second hardcoded god list.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")

local description = {}

-- Gather only human-facing phrases. Stable event IDs establish display
-- order, so changing file names or layer discovery order cannot reshuffle
-- the description or consume a seeded gameplay draw.
local function phrases(responses)
    local entries = {}

    for event_id, rule in pairs(responses or {}) do
        if rule.description and rule.description ~= "" then
            entries[#entries + 1] = {
                event_id = event_id,
                text = rule.description,
            }
        end
    end

    table.sort(entries, function(left, right)
        return left.event_id < right.event_id
    end)

    return entries
end

-- A god without conduct rules can still have behavior-based piety such as
-- Xom's mood; its conduct list is intentionally empty.
function description.for_god(god_id)
    local god = catalog.get(categories.GODS, god_id)

    if not god.conduct_module then
        return {
            likes = {},
            dislikes = {},
        }
    end

    local rules = require(god.conduct_module)

    return {
        likes = phrases(rules.likes),
        dislikes = phrases(rules.dislikes),
    }
end

return description
