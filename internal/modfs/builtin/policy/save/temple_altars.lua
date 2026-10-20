-- A saved Temple floor must still match the one-time plan chosen on D:1.
-- Each generic source B altar receives one exact god identity; a save cannot
-- invent another god, duplicate an altar, or silently lose one of the gods.
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local glyphs = require("constants.vault_glyphs")
local plan = require("policy.generation.temple.plan")

local temple_altars = {}

-- Check the placed floor against the effective selected map and ordered
-- partition. Altar positions may differ by map, but the god set is fixed.
local function validate_level(level, chosen)
    if level.vault_id ~= chosen.map_id then
        error("Temple altar floor has the wrong source map")
    end

    local expected = {}
    local found = {}
    local positions = {}
    local count = 0

    for _, god_id in ipairs(chosen.main_god_ids) do
        expected[god_id] = true
    end

    for _, record in ipairs(level.vault_records or {}) do
        if record.identity == glyphs.terrain.B then
            local god_id = record.arguments and record.arguments.god_id
            local position = record.x .. ":" .. record.y

            if record.kind ~= effects.SOURCE_FEATURE or
                record.source_id ~= chosen.map_id or
                record.pending or record.overridden or
                not expected[god_id] or found[god_id] or
                positions[position] then
                error("Temple altar record disagrees with its saved plan")
            end

            found[god_id] = true
            positions[position] = true
            count = count + 1
        end
    end

    if count ~= chosen.altar_count then
        error("Temple altar count disagrees with its saved plan")
    end
end

-- Only a reached Temple has placed altars. An unvisited Temple keeps its
-- plan but has no level record yet, which is valid across save and restore.
function temple_altars.validate(_, input)
    local chosen = input.temple_plan

    plan.validate(chosen)

    for _, level in ipairs(input.levels or {}) do
        if level.branch_id == branches.BRANCH_TEMPLE then
            validate_level(level, chosen)
        end
    end

    return {}
end

register.policy({
    id = "save.validate_temple_altars",
    run = temple_altars.validate,
})

return temple_altars
