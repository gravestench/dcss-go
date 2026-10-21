-- The rootless Vestibule is not part of the ordinary branch schedule.
-- Validate its source map, five wings, four branch gates, and return arch
-- directly against the effective mod catalog before a save resumes.
local branches = require("ids.branches")
local terrain = require("constants.terrain")
local levels = require("policy.generation.branch_levels")
local vaults = require("policy.generation.vaults.catalog")

local hell = {}

local wing_tags = {
    vestibule_dis = true,
    vestibule_tar = true,
    vestibule_coc = true,
    vestibule_geh = true,
    vestibule_geryon = true,
}

local branch_gates = {
    terrain.DNGN_ENTER_DIS,
    terrain.DNGN_ENTER_GEHENNA,
    terrain.DNGN_ENTER_COCYTUS,
    terrain.DNGN_ENTER_TARTARUS,
}

-- Source wings must remain one each even after a mod changes the effective
-- helper files. IDs alone cannot prove the five required map roles.
local function validate_wings(level)
    local seen = {}

    for _, id in ipairs(level.vault_ids or {}) do
        local definition = vaults.get(id)

        for tag in pairs(wing_tags) do
            if definition.tags[tag] then
                seen[tag] = (seen[tag] or 0) + 1
            end
        end
    end

    for tag in pairs(wing_tags) do
        if seen[tag] ~= 1 then
            error("saved Vestibule lacks one " .. tag .. " wing")
        end
    end
end

-- The saved terrain, not a pending DES instruction, must carry every live
-- gate. The entry is one of the authored return arches after projection.
local function validate_gates(level, state)
    local counts = {}

    for _, row in ipairs(level.cells) do
        for _, feature in ipairs(row) do
            counts[feature] = (counts[feature] or 0) + 1
        end
    end

    if (counts[terrain.DNGN_EXIT_HELL] or 0) < 1 or
        level.cells[state.entry_y + 1][state.entry_x + 1] ~=
            terrain.DNGN_EXIT_HELL then
        error("saved Vestibule has no valid return arch")
    end

    for _, feature in ipairs(branch_gates) do
        if (counts[feature] or 0) < 1 then
            error("saved Vestibule lacks " .. feature)
        end
    end
end

-- A return record is mandatory after the first entry, while an unopened
-- Hell run has neither a session record nor a generated Vestibule level.
function hell.validate(by_id, state)
    local id = levels.id(branches.BRANCH_VESTIBULE, 1)
    local level = by_id[id]

    for other_id, other in pairs(by_id) do
        if other.branch_id == branches.BRANCH_VESTIBULE and
            other_id ~= id then
            error("saved Vestibule has an extra level")
        end
    end

    if not state or not state.vestibule_level_id then
        if level then
            error("saved Vestibule has no Hell return state")
        end

        return
    end

    if not level or state.vestibule_level_id ~= id or
        level.branch_id ~= branches.BRANCH_VESTIBULE or
        level.local_depth ~= 1 or level.vault_id ~=
            "vestibule_of_hell_subvaulted" or
        #level.cells ~= 70 or #level.cells[1] ~= 80 or
        #level.stairs ~= 0 or level.initial_monsters < 3 or
        level.initial_monsters > 36 or
        state.entry_x < 0 or state.entry_x >= 80 or
        state.entry_y < 0 or state.entry_y >= 70 then
        error("saved Vestibule has invalid identity or geometry")
    end

    local site = state.return_site

    if not site or site.level_id == id or
        not by_id[site.level_id] then
        error("saved Hell state has no outside return level")
    end

    validate_wings(level)
    validate_gates(level, state)
end

return hell
