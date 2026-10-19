-- Avatar song pulls one mesmerised player step toward the singer, without
-- putting a non-swimmer in dangerous water or moving through a solid wall.
-- Source: mon-ench.cc:_merfolk_avatar_movement_effect.
-- Example: pull.apply(ctx, avatar, player) returns false when the first
-- path cell is occupied by a hostile monster.
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local flight = require("policy.combat.flight")
local forms = require("constants.form_ids")
local flags = require("constants.monster_flags")
local habitat = require("policy.combat.monster_habitat")
local resistance = require("policy.combat.player_resistance")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")
local water = require("policy.character.water")

local pull = {}
local SIGHT_RADIUS = 7

-- A non-player actor can trade places only if it is friendly, mobile, and
-- awake. The batch grid move then keeps both position indexes consistent.
local function can_swap(ctx, actor)
    if not targets.allied(ctx, actor) or
        ctx:has(actor, component.PARALYSIS) then
        return false
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get("monsters", state.kind_id)
    local stasis = ctx:get(actor, component.MONSTER_STASIS)

    if stasis and (stasis.hibernating or
        stasis.petrified_aut > 0) then
        return false
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STATIONARY then
            return false
        end
    end

    return true
end

-- Refuse dislodging when the player is held, immobilized, clear-minded,
-- or rooted. These are source actor checks before tracing a route.
local function can_dislodge(ctx, player)
    if ctx:has(player, component.PLAYER_CONSTRICTION) or
        resistance.clarity(ctx, player) then
        return false
    end

    local paralysis = ctx:get(player,
        component.PLAYER_PARALYSIS)
    local petrification = ctx:get(player,
        component.PLAYER_PETRIFICATION)
    local sleep = ctx:get(player, component.PLAYER_SLEEP)
    local form = ctx:get(player, component.PLAYER_FORM)

    return (not paralysis or paralysis.remaining_aut <= 0) and
        (not petrification or petrification.petrified_aut <= 0) and
        (not sleep or sleep.remaining_aut <= 0) and
        (not form or form.form_id ~= forms.TREE)
end

-- Pulling is physical movement, so a flying or swimming player may enter
-- terrain that would be dangerous to an ordinary land-bound character.
local function safe_for_player(ctx, player, level_id, x, y)
    if not ctx:walkable(level_id, x, y) then
        return false
    end

    if flight.active(ctx, player) then
        return true
    end

    local feature = ctx:cell(level_id, x, y)

    return feature ~= terrain.DNGN_LAVA and
        (feature ~= terrain.DNGN_DEEP_WATER or
            water.can_swim(ctx, player))
end

-- A route supplies the first safe direction rather than teleporting or
-- pulling the player through intervening terrain.
function pull.apply(ctx, caster, player)
    if not can_dislodge(ctx, player) then
        return false
    end

    local origin = ctx:get(player, component.POSITION)
    local singer = ctx:get(caster, component.POSITION)

    if not origin or not singer or
        origin.level_id ~= singer.level_id then
        return false
    end

    local dx, dy, found = ctx:route_step(origin.level_id,
        origin.x, origin.y, singer.x, singer.y, caster)

    if not found then
        return false
    end

    local x = origin.x + dx
    local y = origin.y + dy

    if not ctx:visible_no_trans(origin.level_id,
        singer.x, singer.y, SIGHT_RADIUS, x, y) then
        return false
    end

    local occupant = ctx:actor_at(origin.level_id, x, y)

    if not safe_for_player(ctx, player, origin.level_id, x, y) then
        return false
    end

    if occupant then
        if not can_swap(ctx, occupant) or
            not habitat.at(ctx, occupant, origin.level_id,
                origin.x, origin.y) then
            return false
        end

        ctx:move_actors({
            {
                actor = player,
                level_id = origin.level_id,
                x = x,
                y = y,
            },
            {
                actor = occupant,
                level_id = origin.level_id,
                x = origin.x,
                y = origin.y,
            },
        })
    else
        ctx:move_actor(player, origin.level_id, x, y)
    end

    ctx:emit(channels.SPELL,
        "The pull of its song draws you forwards.")

    return true
end

return pull
