local component = require("constants.component")
local monsters = require("ids.monsters")

local slime_blob = {}

local names = {
    [2] = "large slime creature",
    [3] = "very large slime creature",
    [4] = "enormous slime creature",
    [5] = "titanic slime creature",
}

-- DES writes merged slimes by display name. Keep the four source sizes in
-- one place so aliases, actor state, and messages cannot disagree.
function slime_blob.size_for_name(name)
    for size, source_name in pairs(names) do
        if name == source_name then
            return size
        end
    end

    return nil
end

-- Only slime creatures may carry this size. An absent component means the
-- ordinary one-body profile, avoiding extra state on every monster.
function slime_blob.size(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)

    if not actor or actor.kind_id ~= monsters.MONS_SLIME_CREATURE then
        return 1
    end

    local state = ctx:get(entity, component.SLIME_BLOB)

    return state and state.size or 1
end

-- Source merged bodies multiply their catalog melee damage before normal
-- combat defenses. This is shared by ordinary and summoned slimes.
function slime_blob.attack_damage(ctx, entity, base_damage)
    return base_damage * slime_blob.size(ctx, entity)
end

-- Use the source-sized name at the message boundary, not a second catalog
-- entry; all sizes remain the same monster species for gameplay rules.
function slime_blob.name(ctx, entity, ordinary_name)
    return names[slime_blob.size(ctx, entity)] or ordinary_name
end

return slime_blob
