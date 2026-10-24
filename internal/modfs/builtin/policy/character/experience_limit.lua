-- Example: One Ru experience sacrifice lowers a level-27 cap before advancement.
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local catalog = require("policy.catalog")
local component = require("constants.component")
local formulas = require("policy.character.formulas")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local experience_limit = {}

-- Source: player-act.cc:get_max_xl; RU_SAC_XP_LEVELS is one.
-- Ru's level sacrifice subtracts from the ordinary experience cap used by advancement.
function experience_limit.max_level(ctx, player)
    local penalty = effects.sum(ctx, player,
        capabilities.MAX_LEVEL_PENALTY)

    return math.max(1, 27 - penalty)
end

-- Source exp_needed with its implicit species aptitude shifts the level
-- threshold by every Inexperienced rank. A sacrifice therefore makes the
-- *current* level more expensive, not merely the final level cap lower.
function experience_limit.needed(ctx, player, level)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", identity.species_id)
    local sacrificed = levels.base(ctx, player,
        mutations.MUT_INEXPERIENCED)

    return formulas.experience_needed(level + sacrificed,
        species.xp)
end

-- Return the earned XL under the player's current sacrifice rank. This is
-- used at save validation and after level loss, not a copied formula.
function experience_limit.earned_level(ctx, player, total_xp, maximum)
    local level = 1

    maximum = maximum or experience_limit.max_level(ctx, player)

    while level < maximum and
        total_xp >= experience_limit.needed(ctx, player,
            level + 1) do
        level = level + 1
    end

    return level
end

-- The displayed fraction uses the same shifted thresholds as advancement.
-- At the cap there is no next level to fill.
function experience_limit.progress(ctx, player, total_xp, level)
    local current = experience_limit.needed(ctx, player, level)

    if total_xp < current then
        error("XL" .. level .. " lacks required experience")
    end

    if level >= experience_limit.max_level(ctx, player) then
        return 0
    end

    local next_xp = experience_limit.needed(ctx, player,
        level + 1)

    return math.floor((total_xp - current) * 100 /
        (next_xp - current))
end

-- Preserve progress through an XL band when a potion or level adjustment
-- moves the player to another band under the current Ru sacrifice rank.
function experience_limit.adjusted_total(ctx, player, total,
    current, target)
    local old_min = experience_limit.needed(ctx, player, current)
    local old_max = experience_limit.needed(ctx, player,
        current + 1)
    local new_min = experience_limit.needed(ctx, player, target)
    local new_max = experience_limit.needed(ctx, player,
        target + 1)

    return new_min + math.floor((new_max - new_min) *
        (total - old_min) / (old_max - old_min))
end

return experience_limit
