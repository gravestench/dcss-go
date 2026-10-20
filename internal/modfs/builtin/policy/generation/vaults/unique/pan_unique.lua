-- Theory of operation: Pan's optional unique maps do not use the ordinary
-- place_unique draw. Each source veto checks the run's unique history;
-- the four lords also require their matching rune before they can appear.
-- Ignacio has a separate run-wide chance gate that is rolled only once.
local monsters = require("ids.monsters")
local runes = require("constants.runes")
local policy = {}

-- A Pan Mennas map remains eligible until he has appeared anywhere in
-- the run, even if that actor was later killed.
local function mennas(api)
    return api:unique_seen(monsters.MONS_MENNAS)
end

-- Source Pan lord maps require the associated rune to have been found.
-- Keep this rule shared, while each callback names its own exact ID.
local function lord(api, monster_id, rune_id)
    return api:unique_seen(monster_id) or not api:has_rune(rune_id)
end

-- The fiery lord can enter after the fiery rune is taken.
local function cerebov(api)
    return lord(api, monsters.MONS_CEREBOV, runes.FIERY)
end

-- The dark lord can enter after the dark rune is taken.
local function gloorx_vloq(api)
    return lord(api, monsters.MONS_GLOORX_VLOQ, runes.DARK)
end

-- The glowing lord can enter after the glowing rune is taken.
local function mnoleg(api)
    return lord(api, monsters.MONS_MNOLEG, runes.GLOWING)
end

-- The magical lord can enter after the magical rune is taken.
local function lom_lobon(api)
    return lord(api, monsters.MONS_LOM_LOBON, runes.MAGICAL)
end

-- Ignacio's source chance depends on the square of Pan runes. The first
-- successful gate fixes a run-wide allow/forbid coinflip for later levels.
local function ignacio(api)
    if api:unique_seen(monsters.MONS_IGNACIO) then
        return true
    end

    local state = api:pan_unique_state(monsters.MONS_IGNACIO)

    if not state.rolled then
        local count = api:pan_rune_count()

        if api:roll(100) >= count * count then
            return true
        end

        state.rolled = true
        state.forbidden = api:roll(2) == 0
    end

    return state.forbidden
end

policy.mennas = mennas
policy.cerebov = cerebov
policy.gloorx_vloq = gloorx_vloq
policy.mnoleg = mnoleg
policy.lom_lobon = lom_lobon
policy.ignacio = ignacio

return policy
