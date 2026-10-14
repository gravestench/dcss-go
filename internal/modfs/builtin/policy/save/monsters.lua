local catalog = require("policy.catalog")
local roster = require("policy.population.roster")
local entities = require("policy.save.entities")
local inventory = require("policy.save.monster_inventory")
local links = require("policy.save.links")
local net = require("policy.combat.net")
local poison = require("policy.combat.monster_poison")
local slow = require("policy.combat.monster_slow")

local function has_flag(definition, id)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == id then
            return true
        end
    end

    return false
end

local function validate_ai(ctx, entity, ai, position, definition, current_aut)
    local retreat_limit = math.max(2, math.floor(definition.speed / 10)) - 1

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

register.policy({
    id = "save.validate_monsters",
    run = function(ctx, input)
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

            if not fixed then
                local level_id = position.level_id
                live_by_level[level_id] = (live_by_level[level_id] or 0) + 1

                if live_by_level[level_id] > (budgets[level_id] or 0) then
                    error("Dungeon:" .. level_id .. " has too many live monsters")
                end
            end

            if not allowed[actor.kind_id] then
                error("unsupported melee attacker " .. actor.kind_id .. " in fixed Dungeon scenario")
            end

            local definition = catalog.get("monsters", actor.kind_id)
            local profile = roster.profile(actor.kind_id)

            if fixed and seen[actor.kind_id] then
                error("duplicate fixed animal " .. actor.kind_id)
            end

            seen[actor.kind_id] = true

            if health.max < profile.minimum or health.max > profile.maximum then
                error("impossible fixed monster maximum HP " .. health.max)
            end

            if not slow.validate(ctx, entity, definition, actor) then
                error("fixed monster " .. actor.kind_id .. " has wrong speed " .. actor.speed)
            end

            validate_ai(ctx, entity, ai, position, definition, input.current_aut)
            net.validate(ctx, entity, position)
            poison.validate(ctx, entity)
        end

        return {}
    end,
})
