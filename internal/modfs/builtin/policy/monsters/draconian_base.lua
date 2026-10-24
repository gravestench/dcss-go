-- Source draconian jobs have a fixed default color, while DES may choose
-- another colored base. Only live jobs own this state; ordinary colored
-- draconians already express their color in the catalog class itself.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local monsters = require("ids.monsters")

local base = {}

-- These are the six source _draconian_combos. Grey and pale draconians
-- remain valid authored bases even though no ordinary job defaults to them.
local defaults = {
    [monsters.MONS_DRACONIAN_STORMCALLER] =
        monsters.MONS_WHITE_DRACONIAN,
    [monsters.MONS_DRACONIAN_MONK] = monsters.MONS_GREEN_DRACONIAN,
    [monsters.MONS_DRACONIAN_SHIFTER] =
        monsters.MONS_PURPLE_DRACONIAN,
    [monsters.MONS_DRACONIAN_ANNIHILATOR] =
        monsters.MONS_YELLOW_DRACONIAN,
    [monsters.MONS_DRACONIAN_KNIGHT] = monsters.MONS_BLACK_DRACONIAN,
    [monsters.MONS_DRACONIAN_SCORCHER] = monsters.MONS_RED_DRACONIAN,
}

-- A job ID is a role, not a colored species. This test also excludes Tiamat,
-- whose source corpse deliberately uses the generic draconian species.
function base.is_job(kind_id)
    return defaults[kind_id] ~= nil
end

-- A legal base is a colored source species of the draconian genus. Catalog
-- equality excludes jobs and the generic draconian sentinel.
function base.valid_color(kind_id)
    if not kind_id or kind_id == "" or
        kind_id == monsters.MONS_DRACONIAN then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, kind_id)

    return definition.genus_id == monsters.MONS_DRACONIAN and
        definition.species_id == kind_id and
        definition.leaves_corpse
end

-- Explicit DES base colors take priority over the fixed default, but a
-- malformed override must fail at placement before a saved actor exists.
function base.for_job(kind_id, authored_id)
    local ordinary = defaults[kind_id]

    if not ordinary then
        return nil
    end

    local chosen = authored_id and authored_id ~= "" and
        authored_id or ordinary

    if not base.valid_color(chosen) then
        error("invalid draconian base " .. tostring(chosen) ..
            " for " .. kind_id)
    end

    return chosen
end

-- A colored base adds draconian traits but does not replace the job's HP
-- dice. Other kinds, notably corpse templates, still use their chosen base
-- as the spawn profile when they have one.
function base.profile_kind(kind_id, authored_id)
    if base.is_job(kind_id) then
        return kind_id
    end

    return authored_id and authored_id ~= "" and
        authored_id or kind_id
end

-- A saved live job must own the color it would have received at placement.
-- Once polymorphed, any old vault override belongs to the source body; a
-- newly borrowed draconian job receives its own default color instead.
function base.validate_actor(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)
    local current = ctx:get(entity, component.MONSTER_DRACONIAN_BASE)
    local form = ctx:get(entity, component.MONSTER_POLYMORPH)
    local overrides = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)
    local authored_id = not form and overrides and overrides.base_id
    local expected = base.for_job(actor.kind_id, authored_id)

    if (expected and (not current or current.base_id ~= expected)) or
        (not expected and current) then
        error("monster " .. ctx:id(entity) ..
            " has invalid draconian base")
    end
end

return base
