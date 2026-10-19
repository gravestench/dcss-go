local component = require("constants.component")
local landing = require("policy.combat.monster_displacement.landing")
local relocate = require("policy.combat.monster_displacement.relocate")
local streams = require("constants.rng_streams")
local strength = require("policy.combat.monster_summons.strength")
local targets = require("policy.ai.targets")
local attitudes = require("constants.attitude")

local allies = {}

-- Source monster_near_iterator sees aligned actors in caster sight. The
-- distance test differs between an encirclement and a rescue blink.
function allies.candidates(ctx, caster, focus, mode)
    local origin = ctx:get(caster, component.POSITION)
    local result = {}

    if not origin or not focus then
        return result
    end

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if entity ~= caster and
            targets.attitude(ctx, caster) ~= attitudes.NEUTRAL and
            targets.real_attitude(ctx, entity) ~= attitudes.NEUTRAL and
            targets.allied(ctx, caster) ==
                targets.real_allied(ctx, entity) and
            relocate.can_move(ctx, entity) then
            local position = ctx:get(entity, component.POSITION)
            local health = ctx:get(entity, component.HEALTH)
            local from_caster = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))
            local from_foe = math.max(math.abs(position.x - focus.x),
                math.abs(position.y - focus.y))
            local useful = mode == "encircle" and from_foe > 1 or
                mode == "away" and from_foe < 3

            if health.current > 0 and
                position.level_id == origin.level_id and
                from_caster <= 7 and useful and
                ctx:visible(origin.level_id, origin.x, origin.y, 7,
                    position.x, position.y) then
                result[#result + 1] = entity
            end
        end
    end

    return result
end

-- Shuffle a dense candidate array on the saved monster-spell stream.
-- Source group spells randomize actors before trying their landing cells.
local function shuffle(ctx, values)
    for index = #values, 2, -1 do
        local chosen = ctx:random(streams.MONSTER_SPELL, index) + 1

        values[index], values[chosen] = values[chosen], values[index]
    end
end

-- Only successful relocations consume the source HD-based move limit.
-- Encircling allies also spend energy and seek their caster's planned foe.
function allies.move(ctx, caster, plan, mode)
    local values = allies.candidates(ctx, caster, plan, mode)
    local hd = strength.spell_hd(ctx, caster)
    local range = math.floor(hd / 4)
    local extra = range > 0 and ctx:random(streams.MONSTER_SPELL,
        range) or 0
    local limit = math.max(1, math.floor(hd / 8) + extra)
    local moved = 0

    shuffle(ctx, values)

    for _, entity in ipairs(values) do
        if moved >= limit then
            break
        end

        local x, y

        if mode == "encircle" then
            x, y = landing.near(ctx, entity, plan, 1)
        else
            x, y = landing.weighted(ctx, entity, plan,
                false, false)
        end

        if x and relocate.move(ctx, entity, x, y, entity) then
            moved = moved + 1

            if mode == "encircle" then
                local state = ctx:get(entity, component.AI)

                if state then
                    state.behavior = "seek"
                    state.target_x = plan.x
                    state.target_y = plan.y
                    state.memory_until_aut = ctx:aut() + 250
                    ctx:set(entity, component.AI, state)
                end

                local energy = ctx:get(entity,
                    component.MONSTER_ENERGY)

                if energy then
                    -- Source drain_action_energy delays only an actor
                    -- already ready to act; an idle actor owes no debt.
                    if energy.points >= 80 then
                        energy.points = 80 - (1 + ctx:random(
                            streams.MONSTER_SPELL, 10))
                        ctx:set(entity, component.MONSTER_ENERGY,
                            energy)
                    end
                end
            end
        end
    end

    return moved
end

return allies
