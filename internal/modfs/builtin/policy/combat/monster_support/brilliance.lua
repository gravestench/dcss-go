local component = require("constants.component")
local duration = require("policy.combat.monster_support.duration")
local display = require("policy.combat.monster_support.display")
local flags = require("constants.monster_spell_flags")
local spellbook = require("policy.combat.monster_spellbook")
local targets = require("policy.ai.targets")

local brilliance = {}

-- A positive caster timer is the only source of an active aura.
function brilliance.active(ctx, caster)
    local state = ctx:get(caster, component.MONSTER_BRILLIANCE_AURA)

    return state ~= nil and state.remaining_aut > 0
end

-- Spell power and the AI's second choice both consult this saved timer.
function brilliance.empowered(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_EMPOWERED_SPELLS)

    return state ~= nil and state.remaining_aut > 0
end

-- The source's actual-spellcaster test requires a Wizard-flagged book slot,
-- not merely a monster that happens to have a natural ability.
local function wizard_book(ctx, monster)
    local book = spellbook.for_actor(ctx, monster)

    if not book then
        return false
    end

    for _, slot in ipairs(book.slots) do
        for _, flag in ipairs(slot.flags or {}) do
            if flag == flags.WIZARD then
                return true
            end
        end
    end

    return false
end

-- Align by the same hostility policy as combat, then check source LOS.
local function eligible(ctx, caster, ally, origin)
    if ally == caster or ally == ctx:player() or
        targets.enemy(ctx, caster, ally) or
        not wizard_book(ctx, ally) then
        return false
    end

    local position = ctx:get(ally, component.POSITION)
    local health = ctx:get(ally, component.HEALTH)

    if not position or not health or health.current <= 0 or
        position.level_id ~= origin.level_id then
        return false
    end

    local distance = math.max(math.abs(position.x - origin.x),
        math.abs(position.y - origin.y))

    return distance <= 7 and ctx:visible(origin.level_id,
        origin.x, origin.y, 7, position.x, position.y)
end

-- Gather recipients from the ECS in stable entity order, independent of
-- Lua file discovery order or a hardcoded monster ID list.
local function recipients(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)
    local result = {}

    if not origin then
        return result
    end

    for _, ally in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if eligible(ctx, caster, ally, origin) then
            result[#result + 1] = ally
        end
    end

    return result
end

-- Source AI needs a live visible foe and an actual allied spellcaster.
function brilliance.useful(ctx, caster, foe)
    if not foe or brilliance.active(ctx, caster) then
        return false
    end

    local origin = ctx:get(caster, component.POSITION)
    local target = ctx:get(foe, component.POSITION)

    if not origin or not target or origin.level_id ~= target.level_id or
        not ctx:visible(origin.level_id, origin.x, origin.y, 7,
            target.x, target.y) then
        return false
    end

    return #recipients(ctx, caster) > 0
end

-- Refresh each nearby allied Wizard's independent empowerment timer.
-- The caster calls this immediately on cast and on later active actions.
function brilliance.pulse(ctx, caster)
    local allies = recipients(ctx, caster)

    if #allies == 0 then
        ctx:remove(caster, component.MONSTER_BRILLIANCE_AURA)

        return false
    end

    for _, ally in ipairs(allies) do
        local existing = ctx:get(ally,
            component.MONSTER_EMPOWERED_SPELLS)

        -- Source update_ench writes the existing enchant back unchanged.
        -- Only a newly empowered ally rolls a duration and consumes RNG.
        if not existing then
            ctx:add(ally, component.MONSTER_EMPOWERED_SPELLS, {
                remaining_aut = duration.brilliance(ctx, ally),
            })
        end
    end

    return true
end

-- The source aura begins on its caster and immediately empowers allies.
function brilliance.cast(ctx, caster)
    ctx:add(caster, component.MONSTER_BRILLIANCE_AURA, {
        remaining_aut = duration.brilliance(ctx, caster),
    })

    brilliance.pulse(ctx, caster)
    ctx:emit("spell", "The " .. display.name(ctx, caster) ..
        " begins emitting a brilliant aura!")
end

-- Each actor ages only its own aura and recipient status. A still-active
-- caster refreshes allies after its timer ages, as source monster turns do.
function brilliance.tick(ctx, monster, elapsed_aut)
    local caster = ctx:get(monster, component.MONSTER_BRILLIANCE_AURA)
    local recipient = ctx:get(monster,
        component.MONSTER_EMPOWERED_SPELLS)

    if recipient then
        recipient.remaining_aut = math.max(0,
            recipient.remaining_aut - elapsed_aut)

        if recipient.remaining_aut == 0 then
            ctx:remove(monster, component.MONSTER_EMPOWERED_SPELLS)
        else
            ctx:set(monster, component.MONSTER_EMPOWERED_SPELLS,
                recipient)
        end
    end

    if caster then
        caster.remaining_aut = math.max(0,
            caster.remaining_aut - elapsed_aut)

        if caster.remaining_aut == 0 then
            ctx:remove(monster, component.MONSTER_BRILLIANCE_AURA)
        else
            ctx:set(monster, component.MONSTER_BRILLIANCE_AURA, caster)
            brilliance.pulse(ctx, monster)
        end
    end
end

return brilliance
