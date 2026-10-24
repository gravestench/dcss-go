-- Sif's two spell-list powers read the same ECS records as memorisation.
-- Stable spell IDs are returned to the terminal; display labels never act
-- as keys, and sorting removes entity creation order from menu behavior.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local effects = require("policy.magic.effects.registry")
local records = require("policy.character.spell_records")
local selection_kinds = require("constants.selection_kinds")

local spells = {}

-- A forgotten spell needs a known slot; Exegesis needs library knowledge
-- and an implemented Lua effect. Both may list an already known spell.
function spells.options(ctx, player, known_only)
    local result = {}

    for _, entry in ipairs(records.list(ctx, player)) do
        local state = entry.state
        local eligible = known_only and state.known_slot > 0 or
            not known_only and state.in_library and
            effects.get(state.spell_id) ~= nil

        if eligible then
            local definition = catalog.get(categories.SPELLS,
                state.spell_id)

            result[#result + 1] = {
                id = state.spell_id,
                label = definition.name,
            }
        end
    end

    table.sort(result, function(left, right)
        if left.label == right.label then
            return left.id < right.id
        end

        return left.label < right.label
    end)

    return result
end

-- No selection is a free prompt; an explicit ID must match a currently
-- eligible entry, preventing a stale menu row from acting on old knowledge.
function spells.choose(ctx, player, spell_id, known_only, title)
    local options = spells.options(ctx, player, known_only)

    if #options == 0 then
        return nil, { message = known_only and
            "You don't know any spells." or
            "You don't know of any spells!" }
    end

    if not spell_id or spell_id == "" then
        return nil, {
            selection = {
                kind = selection_kinds.SPELL,
                title = title,
                options = options,
            },
        }
    end

    for _, option in ipairs(options) do
        if option.id == spell_id then
            return catalog.get(categories.SPELLS, spell_id), nil
        end
    end

    return nil, { message = "That spell is not available." }
end

return spells
