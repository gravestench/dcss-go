-- Theory of operation: every visit rolls one source cloud type for the
-- shaft's fog machine. The machine is a typed marker and becomes an ECS
-- entity during population; its cloud timing survives save and restore.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

local clouds = {
    [branches.BRANCH_DIS] = {
        "mutagenic fog", "calcifying dust", "acidic fog",
    },
    [branches.BRANCH_GEHENNA] = {
        "mutagenic fog", "flame", "flame",
    },
    [branches.BRANCH_COCYTUS] = {
        "mutagenic fog", "freezing vapour", "thunder",
    },
    [branches.BRANCH_TARTARUS] = {
        "mutagenic fog", "foul pestilence", "degeneration",
    },
}

-- Validation reads the declaration without drawing a cloud. Live map
-- placement makes exactly one layout-stream choice, as the source did.
local function configure(api)
    if api:validating() then
        return
    end

    local choices = clouds[api:branch_id()]

    if not choices then
        error("Hell seeping fissure needs a Hell subbranch")
    end

    local cloud = api:random_from(choices)
    local marker = '^ = lua:fog_machine { cloud_type = "' .. cloud ..
        '", pow_min = 5, pow_max = 40, delay = 15, size = 1, ' ..
        'walk_dist = 1, spread_rate = 5 }'

    api:emit(directives.MARKER, marker)
end

handler.configure = configure

return handler
