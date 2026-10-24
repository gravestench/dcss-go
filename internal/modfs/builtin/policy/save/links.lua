local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local members = require("policy.population.band_members")
local sequence = require("policy.combat.monster_attack_sequence")
local attack_types = require("constants.monster_attack_types")
local monster_profile = require("policy.combat.monster_profile")
local substances = require("constants.water_hold_substances")

local links = {}

-- Constriction links require same-floor adjacency in the saved positions.
local function adjacent(a, b)
    if a.level_id ~= b.level_id then
        return false
    end

    local dx = math.abs(a.x - b.x)
    local dy = math.abs(a.y - b.y)

    return dx <= 1 and dy <= 1 and (dx ~= 0 or dy ~= 0)
end

-- A band link is valid only while its live leader and member share a
-- floor. Leader death and cross-floor movement remove the link first.
local function validate_followers(ctx)
    for _, entity in ipairs(ctx:query({ component.FOLLOWER })) do
        local follower = ctx:get(entity, component.FOLLOWER)
        local actor = ctx:get(entity, component.ACTOR)
        local ai = ctx:get(entity, component.AI)
        local position = ctx:get(entity, component.POSITION)
        local leader = follower.leader
        local leader_actor = ctx:get(leader, component.ACTOR)
        local leader_health = ctx:get(leader, component.HEALTH)
        local leader_position = ctx:get(leader, component.POSITION)

        if not actor or not ai or not position or
            leader == entity or not leader_actor or
            not leader_health or leader_health.current <= 0 or
            not leader_position or
            leader_position.level_id ~= position.level_id then
            error("entity " .. ctx:id(entity) .. " has an invalid band leader link")
        end

        local leader_form = ctx:get(leader, component.MONSTER_POLYMORPH)
        local leader_kind = leader_form and leader_form.original_kind_id or
            leader_actor.kind_id
        local definition = catalog.get(categories.MONSTERS, leader_kind)
        local profile = definition.band
        local form = ctx:get(entity, component.MONSTER_POLYMORPH)
        local member_kind = form and form.original_kind_id or actor.kind_id
        local origin = ctx:get(entity, component.BAND_ORIGIN)

        if not origin or origin.leader_kind_id ~= leader_kind or
            origin.member_kind_id ~= member_kind or
            not members.allowed(profile, member_kind) or
            (profile.origin_component and
                not ctx:has(entity, profile.origin_component)) then
            error("entity " .. ctx:id(entity) ..
                " has an incompatible band member")
        end
    end
end

-- A direct grip may belong to a player or monster victim. Its source must
-- still have a constricting attack after polymorph and remain adjacent.
local function validate_constriction(ctx)
    for _, victim in ipairs(ctx:query({ component.CONSTRICTION })) do
        local grip = ctx:get(victim, component.CONSTRICTION)
        local victim_health = ctx:get(victim, component.HEALTH)
        local victim_position = ctx:get(victim, component.POSITION)
        local holder = ctx:id(grip.by) ~= 0 and grip.by or nil
        local actor = holder and ctx:get(holder, component.ACTOR)
        local ai = holder and ctx:get(holder, component.AI)
        local health = holder and ctx:get(holder, component.HEALTH)
        local position = holder and ctx:get(holder, component.POSITION)
        local constricts = false

        if actor then
            local base = catalog.get(categories.MONSTERS, actor.kind_id)
            local definition = monster_profile.definition(ctx, holder, base)

            for _, selected in ipairs(sequence.for_actor(ctx, holder,
                definition)) do
                if selected.attack.type_id == attack_types.CONSTRICT then
                    constricts = true
                    break
                end
            end
        end

        if grip.escape_attempts < 0 or grip.escape_attempts > 1000 or
            grip.held_aut < 0 or grip.held_aut > 1000000 or
            not victim_health or victim_health.current <= 0 or
            not victim_position or not actor or not ai or
            not health or health.current <= 0 or not position or
            not adjacent(victim_position, position) or
            not constricts then
            error("actor has invalid direct constriction link")
        end
    end
end

-- A player grip must point back to the monster that owns its constriction state.
local function validate_player_grips(ctx)
    local player = ctx:player()
    local player_health = ctx:get(player, component.HEALTH)
    local player_position = ctx:get(player, component.POSITION)
    local count = 0

    for _, monster in ipairs(ctx:query({
        component.PLAYER_CONSTRICTION,
    })) do
        local grip = ctx:get(monster, component.PLAYER_CONSTRICTION)
        local actor = ctx:get(monster, component.ACTOR)
        local ai = ctx:get(monster, component.AI)
        local health = ctx:get(monster, component.HEALTH)
        local position = ctx:get(monster, component.POSITION)

        if monster == player or grip.by ~= player or
            grip.held_aut < 0 or grip.escape_attempts < 0 or
            grip.escape_attempts > 1000 or not player_health or
            player_health.current <= 0 or not player_position or
            not actor or not ai or not health or health.current <= 0 or
            not position or not adjacent(player_position, position) then
            error("monster has invalid direct player constriction link")
        end

        count = count + 1
    end

    if count > 8 then
        error("player has too many direct constriction links")
    end
end

-- A saved vine hold must point to a living adjacent head. This catches
-- stale handles that could otherwise trap an actor permanently on reload.
local function validate_vine_grips(ctx)
    for _, victim in ipairs(ctx:query({ component.MONSTER_VINE_GRIP })) do
        local grip = ctx:get(victim, component.MONSTER_VINE_GRIP)
        local victim_health = ctx:get(victim, component.HEALTH)
        local victim_position = ctx:get(victim, component.POSITION)
        local head = ctx:get(grip.by, component.MONSTER_VINE)
        local actor = ctx:get(grip.by, component.ACTOR)
        local health = ctx:get(grip.by, component.HEALTH)
        local position = ctx:get(grip.by, component.POSITION)

        if grip.escape_attempts < 0 or grip.escape_attempts > 1000 or
            grip.held_aut < 0 or not victim_health or
            victim_health.current <= 0 or not victim_position or
            not head or not actor or
            actor.kind_id ~= monsters.MONS_SNAPLASHER_VINE or
            not health or health.current <= 0 or not position or
            not adjacent(victim_position, position) then
            error("actor has invalid snaplasher vine grip")
        end
    end
end

-- A water hold can point in either direction. A hit-time substance and
-- adjacent living holder make its eventual release unambiguous.
local function validate_water_holds(ctx)
    for _, victim in ipairs(ctx:query({ component.WATER_HOLD })) do
        local hold = ctx:get(victim, component.WATER_HOLD)
        local victim_health = ctx:get(victim, component.HEALTH)
        local victim_position = ctx:get(victim, component.POSITION)
        local holder_health = ctx:get(hold.by, component.HEALTH)
        local holder_position = ctx:get(hold.by, component.POSITION)
        local valid_substance = hold.substance_id == substances.WATER or
            hold.substance_id == substances.OOZE

        if hold.by == victim or hold.elapsed_aut < 1 or
            hold.elapsed_aut > 1000000 or not valid_substance or
            not victim_health or victim_health.current <= 0 or
            not victim_position or not holder_health or
            holder_health.current <= 0 or not holder_position or
            not adjacent(victim_position, holder_position) or
            not ctx:has(victim, component.ACTOR) or
            not ctx:has(hold.by, component.ACTOR) then
            error("actor has invalid engulf water-hold link")
        end
    end
end

-- Follower, constriction, grip, and water-hold links are checked from both ends.
-- Example: links.validate(ctx) rejects a follower whose leader link is inconsistent.
function links.validate(ctx)
    validate_followers(ctx)
    validate_constriction(ctx)
    validate_player_grips(ctx)
    validate_vine_grips(ctx)
    validate_water_holds(ctx)
end

return links
