-- Crush and Engulf are contact effects even when armour absorbs the
-- physical hit. The saved grip and water-hold owners govern later turns.
local component = require("constants.component")
local catalog = require("policy.catalog")
local eligibility = require("policy.combat.grip_eligibility")
local engulf = require("policy.combat.engulf")
local monsters = require("ids.monsters")
local roll = require("policy.combat.roll")

local holds = {}

-- A direct constrictor may hold one victim. Source octopodes can use up
-- to eight free tentacles; every victim still owns its own saved link.
local function capacity(ctx, attacker)
    local count = 0

    for _, victim in ipairs(ctx:query({ component.CONSTRICTION })) do
        local grip = ctx:get(victim, component.CONSTRICTION)

        if grip.by == attacker then
            count = count + 1
        end
    end

    local actor = ctx:get(attacker, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)

    if definition and definition.genus_id == monsters.MONS_OCTOPODE then
        return count < 8
    end

    return count == 0
end

-- AF_CRUSH starts the grip; constriction damage belongs to the later
-- constrictor turn. Departure hits cannot interrupt movement with a grab.
function holds.crush(ctx, hit)
    if hit.player_moving or
        ctx:has(hit.defender, component.CONSTRICTION) or
        not eligibility.can_engulf(ctx, hit.attacker, hit.defender) or
        not capacity(ctx, hit.attacker) then
        return false
    end

    ctx:add(hit.defender, component.CONSTRICTION, {
        by = hit.attacker,
        escape_attempts = 0,
        held_aut = 0,
    })

    if ctx:has(hit.defender, component.PLAYER) then
        ctx:emit("combat", "The " .. hit.attacker_name .. " grabs you.")
    else
        ctx:emit("combat", "The " .. hit.attacker_name ..
            " grabs the " .. hit.defender_definition.name .. ".")
    end

    return true
end

-- AF_ENGULF rolls two chances in three before checking body rules. The
-- water-hold owner then records the successful holder and substance.
function holds.engulf(ctx, hit)
    local applied = false

    if not hit.player_moving and roll.melee(ctx, 3) < 2 and
        eligibility.can_engulf(ctx, hit.attacker, hit.defender) then
        applied = engulf.on_monster_hit(ctx, hit)

        -- Source returns before water exposure when an already held
        -- victim wins the contact chance but receives no new status.
        if not applied then
            return false
        end
    end

    -- BEAM_WATER exposure follows the contact even when its hold chance
    -- fails. Sticky flame therefore goes out on an ordinary wet hit.
    if ctx:has(hit.defender, component.STICKY_FLAME) then
        ctx:remove(hit.defender, component.STICKY_FLAME)
    end

    return applied
end

return holds
