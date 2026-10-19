-- Source: actor.cc direct constriction and monster.cc:attempt_escape.
local catalog = require("policy.catalog")
local component = require("constants.component")
local confusion = require("policy.magic.player_confusion")
local attributes = require("policy.character.attributes")
local damage = require("policy.magic.damage")
local equipment_rules = require("policy.inventory.equipment")
local forms = require("policy.magic.effects.forms.player")
local monster_defense = require("policy.combat.monster_defense")
local monsters = require("ids.monsters")
local roll = require("policy.combat.roll")
local size = require("constants.size")
local vision = require("policy.character.vision")

local constriction = {}

-- Read monster flags when deciding whether a body can be gripped.
local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- A grip requires a neighboring cell on the same level, including diagonals.
local function adjacent(left, right)
    return left and right and left.level_id == right.level_id and
        math.abs(left.x - right.x) <= 1 and
        math.abs(left.y - right.y) <= 1 and
        (left.x ~= right.x or left.y ~= right.y)
end

-- Share the grip's adjacency rule with callers that preflight attacks.
function constriction.adjacent(left, right)
    return adjacent(left, right)
end

-- Losing constriction releases every monster held by this player, including
-- grips not on the current level.
function constriction.release_all(ctx, player)
    for _, monster in ipairs(ctx:query({ component.PLAYER_CONSTRICTION })) do
        local state = ctx:get(monster, component.PLAYER_CONSTRICTION)

        if state.by == player then
            ctx:remove(monster, component.PLAYER_CONSTRICTION)
        end
    end
end

-- A shield or weapon consumes tentacle capacity before visibility, size, and
-- immunity are passed to the auxiliary attack policy.
function constriction.snapshot(ctx, target, defender, species, worn,
    arms, form_size)
    local player = ctx:player()
    local player_position = ctx:get(player, component.POSITION)
    local target_position = ctx:get(target, component.POSITION)
    local player_monster = catalog.get("monsters", species.monster_id)
    local player_size = size.rank[form_size] or
        size.rank[player_monster.size_id]
    local grips = 0

    for _, monster in ipairs(ctx:query({ component.PLAYER_CONSTRICTION })) do
        local current = ctx:get(monster, component.PLAYER_CONSTRICTION)

        if current.by == player then
            grips = grips + 1
        end
    end

    local free_tentacles = arms - grips

    if worn.shield then
        free_tentacles = free_tentacles - 2
    end

    if worn.weapon then
        local two_handed = equipment_rules.needs_second_hand(ctx, player,
            worn.weapon.definition, species)

        free_tentacles = free_tentacles - (two_handed and 6 or 4)
    end

    local visible = adjacent(player_position, target_position) and
        ctx:visible(player_position.level_id, player_position.x,
            player_position.y, vision.radius(ctx, player),
            target_position.x, target_position.y)

    return {
        target = target,
        can_see = visible,
        adjacent = adjacent(player_position, target_position),
        confused = confusion.active(ctx, player),
        player_size = player_size or size.rank[size.MEDIUM],
        target_size = size.rank[defender.size_id] or size.rank[size.MEDIUM],
        target_immune_to_constriction =
            has_flag(defender.flags, "M_INSUBSTANTIAL") or
            has_flag(defender.flags, "M_SPINY") or
            defender.genus_id == monsters.MONS_JELLY,
        existing_grips = grips,
        free_tentacles = free_tentacles,
    }
end

-- Example: constriction.escape(ctx, monster) with unheld monster -> true escape
-- Repeated monster attempts accumulate against a fresh grip roll until the
-- saved hold is removed.
function constriction.escape(ctx, monster, attempts)
    local state = ctx:get(monster, component.PLAYER_CONSTRICTION)

    if not state then
        return true
    end

    state.escape_attempts = state.escape_attempts + (attempts or 1)
    local progress = ctx:get(state.by, component.PROGRESSION)
    local grip = 1 + roll.melee(ctx, 3 + progress.level)

    if 3 * state.escape_attempts > grip then
        ctx:remove(monster, component.PLAYER_CONSTRICTION)
        ctx:emit("combat", "The monster escapes your grasp.")

        return true
    end

    ctx:set(monster, component.PLAYER_CONSTRICTION, state)

    return false
end

-- Damage ramps with held time, rolls target armour, then scales by actual
-- action AUT; this runs after each player action rather than initial contact.
local function constriction_damage(ctx, monster, definition, held_aut, aut)
    local player = ctx:player()
    local current = attributes.current(ctx, player)
    local form = forms.modifiers(ctx, player)
    local progress = ctx:get(player, component.PROGRESSION)
    local strength = current.strength + form.strength
    local sides = math.max(1, roll.random_divide(ctx, strength, 5))
    local base = 2 + roll.melee(ctx, sides) + roll.melee(ctx, sides)
    local stepdown = math.floor(50 *
        math.log(1 + held_aut / 50) / math.log(2) + 0.5)
    local ramp = roll.random_divide(ctx, base * stepdown, 50)
    local scaled = roll.random_divide(ctx,
        (base + ramp) * (27 + 2 * progress.level), 81)
    local armour = monster_defense.armour(ctx, monster, definition)
    local after_armour = math.max(0, scaled -
        roll.melee(ctx, 1 + math.floor(armour / 2)))

    return roll.random_divide(ctx, after_armour * aut, 10)
end

-- Source: player-reacts.cc:handle_constriction then accum_has_constricted.
function constriction.player_action(ctx, aut)
    local player = ctx:player()
    local player_health = ctx:get(player, component.HEALTH)
    local player_position = ctx:get(player, component.POSITION)

    for _, monster in ipairs(ctx:query({
        component.PLAYER_CONSTRICTION,
        component.HEALTH,
        component.POSITION,
    })) do
        local state = ctx:get(monster, component.PLAYER_CONSTRICTION)
        local health = ctx:get(monster, component.HEALTH)
        local position = ctx:get(monster, component.POSITION)

        if state.by ~= player or not player_health or
            player_health.current <= 0 or health.current <= 0 or
            not adjacent(player_position, position) then
            ctx:remove(monster, component.PLAYER_CONSTRICTION)
        else
            local actor = ctx:get(monster, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            local amount = constriction_damage(ctx, monster, definition,
                state.held_aut, aut)

            health.current = damage.apply(ctx, monster, amount)
            ctx:emit("combat", "You constrict the " .. definition.name .. ".")

            if health.current <= 0 then
                ctx:remove(monster, component.PLAYER_CONSTRICTION)
            else
                state.held_aut = state.held_aut + aut
                ctx:set(monster, component.PLAYER_CONSTRICTION, state)
            end
        end
    end
end

return constriction
