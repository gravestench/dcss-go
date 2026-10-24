-- Example: A successful player spell can paralyse a visible hostile rat at the mutation roll.
-- Source: spl-cast.cc:do_demonic_magic. A successful player spell sends
-- malevolent energy through nearby line-of-sight cells.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local time = require("constants.time")
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local common = require("policy.magic.effects.statuses.common")
local targets = require("policy.ai.targets")
local will = require("policy.magic.effects.zaps.will")

local demonic_magic = {}

-- Filter targets by sight, range, and will before consuming a spell-triggered paralysis attempt.
local function eligible(ctx, player, monster, origin, rank)
    if not targets.enemy(ctx, player, monster) then
        return nil
    end

    local health = ctx:get(monster, component.HEALTH)
    local position = ctx:get(monster, component.POSITION)
    local actor = ctx:get(monster, component.ACTOR)

    if health.current <= 0 or
        common.distance(origin, position) > rank or
        not common.visible(ctx, origin, position, rank) then
        return nil
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if common.has(definition.flags, flags.NO_THREAT) or
        common.has(definition.flags, flags.STASIS) then
        return nil
    end

    return definition
end

-- Roll the spell-stream duration and extend existing paralysis without shortening it.
local function paralyze(ctx, monster, definition)
    local duration = (2 + ctx:random("spell", 4)) * time.AUT_PER_TURN
    local current = ctx:get(monster, component.PARALYSIS)
    local state = {
        remaining_aut = math.max(current and current.remaining_aut or 0,
            duration),
    }

    if current then
        ctx:set(monster, component.PARALYSIS, state)
    else
        ctx:add(monster, component.PARALYSIS, state)
    end

    ctx:emit("spell", "The " .. definition.name .. " suddenly stops moving!")
end

-- Check eligible nearby monsters only after a successful player spell triggers the mutation.
function demonic_magic.on_success(ctx, player, spell)
    local rank = effects.sum(ctx, player,
        capabilities.DEMONIC_MAGIC_RANK)

    if rank < 1 then
        return
    end

    ctx:emit("spell", "Malevolent energies surge around you.")

    local origin = ctx:get(player, component.POSITION)
    local power = spell.level * 6

    for _, monster in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        local definition = eligible(ctx, player, monster, origin, rank)

        if definition and not will.resists(ctx, definition,
            power, monster, nil, player) then
            paralyze(ctx, monster, definition)
        end
    end
end

return demonic_magic
