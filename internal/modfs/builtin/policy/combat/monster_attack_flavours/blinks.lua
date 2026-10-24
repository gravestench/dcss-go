-- Source Blink contact defers movement until every attack slot has run.
-- The melee round owns this transient queue; no save state is needed.
local component = require("constants.component")
local habitat = require("policy.combat.monster_habitat")
local landing = require("policy.combat.monster_displacement.landing")
local landings = require("policy.world.teleport_landings")
local relocate = require("policy.combat.monster_displacement.relocate")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")
local translocation = require("policy.scrolls.translocation")

local blinks = {}

-- Final effects with the same blinker and partner merge in source. Keep
-- the first event so two qualifying hits cannot move an actor twice.
local function enqueue(pending, attacker, partner)
    if not pending then
        error("blink contact requires its melee round queue")
    end

    for _, event in ipairs(pending) do
        if event.attacker == attacker and event.partner == partner then
            return
        end
    end

    pending[#pending + 1] = {
        attacker = attacker,
        partner = partner,
    }
end

-- Damaging Blink hits roll one in three unless this was a departure hit.
function blinks.self(ctx, hit)
    if hit.damage_done <= 0 or hit.player_moving or
        roll.melee(ctx, 3) ~= 0 then
        return false
    end

    enqueue(hit.pending_blinks, hit.attacker)

    return true
end

-- Blink With has a separate coin flip and remembers the original victim.
function blinks.with_target(ctx, hit)
    if hit.damage_done <= 0 or hit.player_moving or
        roll.melee(ctx, 2) ~= 1 then
        return false
    end

    enqueue(hit.pending_blinks, hit.attacker, hit.defender)

    return true
end

-- The partner's destination follows the source fair-adjacent iterator.
-- Reservoir sampling gives each legal free cell equal probability.
local function partner_cell(ctx, partner, origin)
    local count = 0
    local chosen_x
    local chosen_y

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = origin.x + dx
                local y = origin.y + dy
                local free = not ctx:actor_at(origin.level_id, x, y) and
                    landings.allowed(ctx, origin.level_id, x, y)
                local habitable = false

                if free and ctx:has(partner, component.PLAYER) then
                    habitable = translocation.can_land(ctx, partner,
                        origin.level_id, x, y)
                elseif free then
                    habitable = habitat.at(ctx, partner,
                        origin.level_id, x, y)
                end

                if habitable then
                    count = count + 1

                    if roll.melee(ctx, count) == 0 then
                        chosen_x = x
                        chosen_y = y
                    end
                end
            end
        end
    end

    return chosen_x, chosen_y
end

-- Recheck life and teleport restrictions when the final effect fires:
-- later contact slots may have killed or anchored either actor.
local function resolve_one(ctx, event)
    local attacker = event.attacker
    local partner = event.partner
    local health = ctx:get(attacker, component.HEALTH)

    if not health or health.current <= 0 or
        not relocate.can_move(ctx, attacker) then
        return
    end

    if partner then
        local partner_health = ctx:get(partner, component.HEALTH)

        if not partner_health or partner_health.current <= 0 or
            not relocate.can_move(ctx, partner) then
            return
        end
    end

    local x, y = landing.ordinary(ctx, attacker, false,
        streams.MELEE)

    if not x or not relocate.move(ctx, attacker, x, y, attacker,
        true, false, streams.MELEE) then
        return
    end

    if not partner then
        return
    end

    local origin = ctx:get(attacker, component.POSITION)
    local partner_x, partner_y = partner_cell(ctx, partner, origin)

    if partner_x then
        relocate.move(ctx, partner, partner_x, partner_y,
            attacker, true, false, streams.MELEE)
    end
end

-- The round, not each contact, drains the queue after all attack slots.
function blinks.resolve(ctx, pending)
    for _, event in ipairs(pending) do
        resolve_one(ctx, event)
    end
end

return blinks
