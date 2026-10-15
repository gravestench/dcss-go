-- Source: spl-selfench.cc:cast_corpse_rot, mon-death.cc:_corpse_rot,
-- and cloud.cc:CLOUD_MIASMA.
local time = require("constants.time")
local component = require("constants.component")
local species_ids = require("ids.species")
local death_hooks = require("policy.combat.death_hooks")
local miasma = require("policy.magic.effects.statuses.miasma_cloud")
local poison = require("policy.combat.monster_poison")
local catalog = require("policy.catalog")
local slow = require("policy.combat.monster_slow")
local brands = require("policy.combat.brands")
local player_resistance = require("policy.combat.player_resistance")
local statuses = require("policy.magic.effects.statuses.player")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local common = require("policy.magic.effects.statuses.common")
local player_slow = require("policy.character.slow")

local rot = {}

local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function monster_immune(definition)
    for _, resistance in ipairs(definition.resistances or {}) do
        if resistance.id == "MR_RES_MIASMA" and
            resistance.level > 0 then
            return true
        end
    end

    return has(definition.holiness, "MH_HOLY") or
        has(definition.holiness, "MH_DEMONIC") or
        has(definition.holiness, "MH_UNDEAD") or
        has(definition.holiness, "MH_NONLIVING")
end

local function player_immune(ctx, player)
    if effects.sum(ctx, player,
        capabilities.MIASMA_IMMUNITY) > 0 then
        return true
    end

    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", identity.species_id)
    local form = ctx:get(player, component.PLAYER_FORM)

    if identity.species_id == species_ids.SP_GARGOYLE or
        identity.species_id == species_ids.SP_DJINNI or
        species.undead_type == "US_UNDEAD" then
        return true
    end

    return form and (form.form_id == "lich" or
        form.form_id == "statue" or form.form_id == "storm")
end

local function random_divide(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

function rot.cast(ctx, player, _, _, power)
    local state = ctx:get(player, component.AREA_STATUS) or {
        corpse_rot_aut = 0,
        corpse_rot_power = 0,
        toxic_radiance_aut = 0,
        toxic_radiance_power = 0,
        noxious_bog_aut = 0,
    }
    local bound = 1 + random_divide(ctx, power * 3, 5)
    local added = 10 + ctx:random("spell", bound)

    state.corpse_rot_aut = math.min(500,
        state.corpse_rot_aut + added * time.AUT_PER_TURN)
    state.corpse_rot_power = power

    if ctx:has(player, component.AREA_STATUS) then
        ctx:set(player, component.AREA_STATUS, state)
    else
        ctx:add(player, component.AREA_STATUS, state)
    end

    ctx:emit("spell", "You radiate decay.")
end

local function place(ctx, origin, x, y)
    if not miasma.available(ctx, origin.level_id, x, y) then
        return false
    end

    local duration = 2 + math.floor((ctx:random("spell", 8) +
        ctx:random("spell", 9)) / 2)

    return miasma.place(ctx, origin.level_id, x, y,
        duration * time.AUT_PER_TURN) ~= nil
end

-- Called by actor.death after the victim has left the map.
function rot.on_death(ctx, monster, definition, position)
    local player = ctx:player()
    local state = ctx:get(player, component.AREA_STATUS)

    if not state or state.corpse_rot_aut <= 0 or
        not definition.leaves_corpse or
        ctx:has(monster, component.SUMMON) then
        return false
    end

    local origin = ctx:get(player, component.POSITION)

    if not common.visible(ctx, origin, position) then
        return false
    end

    local limit = 1 + ctx:random("spell", 1 +
        random_divide(ctx, state.corpse_rot_power, 25))

    for radius = 1, 2 do
        for dy = -radius, radius do
            for dx = -radius, radius do
                if math.max(math.abs(dx), math.abs(dy)) == radius and
                    place(ctx, origin, origin.x + dx, origin.y + dy) then
                    limit = limit - 1

                    if limit == 0 then
                        return false
                    end
                end
            end
        end
    end

    ctx:emit("spell", "You smell decay.")
    return false
end

function rot.tick(ctx, actor)
    local position = ctx:get(actor, component.POSITION)

    for _, marker in ipairs(ctx:query({ component.MIASMA_CLOUD })) do
        local state = ctx:get(marker, component.MIASMA_CLOUD)

        if state.expires_aut <= ctx:aut() then
            ctx:destroy(marker)
        elseif position and
            position.level_id == state.level_id and
            position.x == state.x and position.y == state.y then
            local health = ctx:get(actor, component.HEALTH)

            if health and health.current > 0 then
                if actor == ctx:player() then
                    if not player_immune(ctx, actor) and
                        not statuses.death_door_active(ctx, actor) then
                        if player_resistance.poison(ctx, actor) < 3 then
                            local amount = 5

                            for _ = 1, 3 do
                                amount = amount + 1 + ctx:random("spell", 12)
                            end

                            brands.poison(ctx, amount, "corpse rot")
                        end

                        if ctx:random("spell", 3) == 0 then
                            local duration = (10 + ctx:random("spell", 5)) *
                                time.AUT_PER_TURN
                            player_slow.apply(ctx, actor,
                                math.floor(duration / time.AUT_PER_TURN))
                        end
                    end
                else
                    local kind = ctx:get(actor, component.ACTOR).kind_id
                    local definition = catalog.get("monsters", kind)

                    if not monster_immune(definition) then
                        poison.apply(ctx, actor, definition, 1,
                            ctx:player(), false)

                        if ctx:random("spell", 3) == 0 then
                            slow.apply(ctx, actor, definition)
                        end
                    end
                end
            end
        end
    end
end

death_hooks.add("magic.status.corpse_rot", rot.on_death)

return rot
