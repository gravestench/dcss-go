local catalog = require("policy.catalog")
local roster = require("policy.population.roster")
local entities = require("policy.save.entities")
local inventory = require("policy.save.monster_inventory")
local links = require("policy.save.links")
local net = require("policy.combat.net")
local poison = require("policy.combat.monster_poison")
local slow = require("policy.combat.monster_slow")
local sticky_flame = require("policy.magic.effects.zaps.sticky_flame")
local summons = require("policy.save.summons")
local summon_branches = require("policy.combat.monster_summons.branches")
local abyss = require("policy.world.abyss")
local component = require("constants.component")

-- Banished monsters have different location requirements from level residents.
local function validate_banishment(ctx, entity, position)
    local origin = ctx:get(entity, component.BANISHMENT)

    if not origin then
        return
    end

    if position.level_id ~= abyss.level_id or
        origin.origin_level_id <= 0 or
        origin.origin_level_id == abyss.level_id or
        not ctx:walkable(origin.origin_level_id,
            origin.origin_x, origin.origin_y) then
        error("monster " .. ctx:id(entity) ..
            " has invalid banishment origin")
    end
end

-- Source monster flags determine which saved states are legal.
local function has_flag(definition, id)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == id then
            return true
        end
    end

    return false
end

-- AI memory deadlines and target cells must be coherent before turns resume.
local function validate_ai(ctx, entity, ai, position, definition, current_aut)
    local retreat_limit = math.max(2, math.floor((definition.speed or 0) / 10)) - 1

    if ai.bat_retreat_actions < 0 or ai.bat_retreat_actions > retreat_limit or
        (ai.bat_retreat_actions > 0 and
            (not has_flag(definition, "M_BATTY") or ai.behavior ~= "wander")) then
        error("monster " .. ctx:id(entity) .. " has invalid bat retreat state")
    end

    if ai.behavior == "chase" then
        if ai.target_x ~= 0 or ai.target_y ~= 0 or ai.memory_until_aut ~= 0 then
            error("legacy monster " .. ctx:id(entity) .. " has a target or memory")
        end
    elseif ai.behavior == "wander" then
        if ai.memory_until_aut ~= 0 or
            ((ai.target_x ~= 0 or ai.target_y ~= 0) and
                not ctx:walkable(position.level_id, ai.target_x, ai.target_y)) then
            error("wandering monster " .. ctx:id(entity) .. " has invalid target or memory")
        end
    elseif ai.behavior == "seek" then
        if not ctx:walkable(position.level_id, ai.target_x, ai.target_y) or
            ai.memory_until_aut < 0 or ai.memory_until_aut > current_aut + 550 then
            error("monster " .. ctx:id(entity) .. " has invalid remembered target")
        end
    else
        error("monster " .. ctx:id(entity) .. " has invalid behavior " .. tostring(ai.behavior))
    end
end

-- Authored stationary monsters omit speed; their saved actor speed is zero.
-- Moving monsters can have a valid temporary slow recorded by its component.
local function valid_speed(ctx, entity, definition, actor)
    if (definition.speed or 0) == 0 then
        return actor.speed == 0 and
            not ctx:has(entity, component.PROJECTILE_SLOW)
    end

    return slow.validate(ctx, entity, definition, actor)
end

-- Roster monsters must match the scenario's allowed profile and starting bounds.
local function validate_roster_monster(ctx, entity, actor, health, position,
    ai, state)
    local polymorph = ctx:get(entity, "magic.monster_polymorph")
    local clone = ctx:get(entity, component.CHAOS_CLONE)
    local roster_id = clone and clone.roster_kind_id or
        polymorph and polymorph.original_kind_id or actor.kind_id

    if clone and (clone.roster_kind_id == "" or
        clone.created_aut > state.current_aut) then
        error("monster " .. ctx:id(entity) .. " has invalid chaos clone")
    end

    if not state.fixed and not clone then
        local banishment = ctx:get(entity, component.BANISHMENT)
        local level_id = banishment and banishment.origin_level_id or
            position.level_id
        local count = (state.live_by_level[level_id] or 0) + 1

        if count > (state.budgets[level_id] or 0) then
            error("Dungeon:" .. level_id .. " has too many live monsters")
        end

        state.live_by_level[level_id] = count
    end

    -- A chaos duplicate can copy an authored vault actor, whose kind is not
    -- part of the ordinary scenario roster. The clone component records its
    -- source kind; the catalog/profile checks below still validate it.
    if not clone and not state.allowed[roster_id] then
        error("unsupported melee attacker " .. roster_id ..
            " in fixed Dungeon scenario")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local profile = roster.profile(roster_id)

    if state.fixed and state.seen[roster_id] and not clone then
        error("duplicate fixed animal " .. roster_id)
    end

    if not clone then
        state.seen[roster_id] = true
    end

    if polymorph and (roster_id == actor.kind_id or
        health.max <= 0 or health.current > health.max) then
        error("invalid polymorphed monster " .. ctx:id(entity))
    end

    if not polymorph and not clone and
        (health.max < profile.minimum or health.max > profile.maximum) then
        error("impossible fixed monster maximum HP " .. health.max)
    end

    if not valid_speed(ctx, entity, definition, actor) then
        error("fixed monster " .. actor.kind_id ..
            " has wrong speed " .. actor.speed)
    end

    validate_ai(ctx, entity, ai, position, definition, state.current_aut)
    net.validate(ctx, entity, position)
    poison.validate(ctx, entity)
    sticky_flame.validate(ctx, entity)
end

local module = {}

-- A caster's spell-specific choices survive reload, so reject impossible
-- branch names and attempt counts before its next AI decision uses them.
local function validate_summon_cast_state(ctx, entity)
    local invitation = ctx:get(entity, component.MONSTER_INVITATION)
    local brothers = ctx:get(entity, component.MONSTER_BROTHERS)

    if invitation and
        not summon_branches.valid_invitation(invitation.branch_id) then
        error("monster " .. ctx:id(entity) ..
            " has invalid Invitation branch")
    end

    if brothers and (brothers.count < 0 or brothers.count > 2) then
        error("monster " .. ctx:id(entity) ..
            " has invalid Brothers in Arms count")
    end
end

-- Vault actors are validated against authored origin overrides instead of roster limits.
local function validate_vault_monster(ctx, entity, actor, health, position,
    ai, current_aut)
    local definition = catalog.get("monsters", actor.kind_id)
    local overrides = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)
    local profile_id = overrides and overrides.base_id ~= "" and
        overrides.base_id or actor.kind_id
    local profile = roster.profile(profile_id)
    if health.max < profile.minimum or health.max > profile.maximum then
        error("vault monster " .. ctx:id(entity) .. " has impossible HP")
    end

    if not valid_speed(ctx, entity, definition, actor) then
        error("vault monster " .. actor.kind_id .. " has wrong speed")
    end

    validate_ai(ctx, entity, ai, position, definition, current_aut)
    net.validate(ctx, entity, position)
    poison.validate(ctx, entity)
    sticky_flame.validate(ctx, entity)
end

-- Monster save validation separates roster, vault, and banished actors because their origins differ.
-- Example: module.run(ctx, input) rejects a banished monster left on an ordinary floor.
function module.run(ctx, input)
    entities.validate(ctx)
    inventory.validate(ctx)
    links.validate(ctx)

    local allowed = roster.allowed(input.scenario_id)
    local fixed = input.scenario_id ~= "fixed-dungeon-population-v1" and
        input.scenario_id ~= "generated-dungeon-basic-v1"
    local seen = {}
    local budgets = {}
    local live_by_level = {}

    if not fixed then
        for _, level in ipairs(input.levels) do
            budgets[level.id] = level.initial_actors
        end
    end

    if input.scenario_id == "generated-dungeon-basic-v1" then
        allowed.MONS_GOBLIN = true
        allowed.MONS_KOBOLD = true
    end

    local roster_state = {
        allowed = allowed,
        fixed = fixed,
        seen = seen,
        budgets = budgets,
        live_by_level = live_by_level,
        current_aut = input.current_aut,
    }

    for _, entity in ipairs(ctx:query({ "core.ai" })) do
        local actor = ctx:get(entity, "core.actor")
        local health = ctx:get(entity, "core.health")
        local position = ctx:get(entity, "core.position")
        local energy = ctx:get(entity, "core.monster_energy")
        local ai = ctx:get(entity, "core.ai")

        if not actor or not health or not position or not energy then
            error("invalid monster entity " .. ctx:id(entity))
        end

        if energy.points < 0 or (input.player_alive and energy.points >= 80) then
            error("monster " .. ctx:id(entity) .. " has invalid action energy")
        end

        if health.current <= 0 then
            error("saved monster " .. ctx:id(entity) .. " has no remaining HP")
        end

        validate_banishment(ctx, entity, position)
        validate_summon_cast_state(ctx, entity)

        local summon = ctx:get(entity, "magic.summon")

        -- Summons follow owner/expiry rules; authored vault actors and roster actors have different origin checks.
        if summon then
            summons.validate(ctx, entity, actor, position, ai,
                summon, input.current_aut)
        elseif ctx:get(entity, component.VAULT_ORIGIN) then
            validate_vault_monster(ctx, entity, actor, health,
                position, ai, input.current_aut)
        else
            validate_roster_monster(ctx, entity, actor, health,
                position, ai, roster_state)
        end
    end

    return {}
end

register.policy({
    id = "save.validate_monsters",
    run = module.run,
})

return module
