-- Theory of operation: source desolation_portal draws one lifetime for O,
-- makes that cell a gate, and supplies the branch-specific wall substitution.
-- Selection tags and chance are explicit in DES because the catalog reads
-- static declarations before it runs hooks. The hook still runs at the
-- source script position so its marker stays attached to the right cell.
local branches = require("ids.branches")
local desolation = require("constants.desolation")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local shared = {}

-- Draw exactly once and encode the result in the source marker. Population
-- materializes a saved ECS clock from this value without touching the RNG.
function shared.portal(api)
    local turns = desolation.MIN_DURATION_TURNS +
        api:roll(desolation.DURATION_RANGE_TURNS)

    api:emit(directives.MARKER,
        "O = lua:timed_marker { low = " .. turns ..
        ", high = " .. turns ..
        ', single_timed = true, entity = "gateway", floor = "' ..
        desolation.EXPIRED_FEATURE .. '" }')
    api:emit(directives.KFEAT,
        "O = " .. desolation.ENTRY_FEATURE)

    -- Vaults provides its own wall type for special rooms. The source
    -- replaces c only there, leaving the Elf ruin walls intact.
    if api:branch_id() == branches.BRANCH_VAULTS then
        api:emit(directives.SUBST, "c = x")
    end
end

-- The twin temple's statues are ruined idols in inspect text, while
-- collision continues to use ordinary granite statue terrain.
function shared.idol(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.DESOLATION_RUINED_IDOL,
    })
end

-- Source dgn.delayed_decay creates a corpse that cannot rot until its cell
-- enters the player's sight. The keyed item is real ECS content; the typed
-- record lets world.delayed_decay release that initial preservation later.
function shared.slug_decay(api)
    api:emit(directives.KITEM,
        "s = never_decay dart slug corpse")
    api:record(effects.DELAYED_DECAY, {
        glyph = "s",
        alternatives = "dart slug corpse",
    })
end

return shared
