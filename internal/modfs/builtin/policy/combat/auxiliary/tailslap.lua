local auxiliary = require("policy.combat.auxiliary")
local attacks = require("constants.auxiliary_attacks")
local component = require("constants.component")
local holiness_ids = require("constants.monster_holiness")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local poison = require("policy.combat.monster_poison")

local tailslap = {
    id = attacks.TAILSLAP.id,
    order = attacks.TAILSLAP.order,
    chance = 50,
    mutation_ids = {
        mutations.MUT_STINGER,
        mutations.MUT_ARMOURED_TAIL,
        mutations.MUT_WEAKNESS_STINGER,
        mutations.MUT_MERTAIL,
        mutations.MUT_CONSTRICTING_TAIL,
    },
}

local function level(ctx, id)
    return levels.effective(ctx, ctx:player(), id)
end

local function has_tail(ctx)
    local player = ctx:get(ctx:player(), component.PLAYER)

    if not player then
        error("tail slap requires player origin")
    end

    return player.species_id:find("^SP_.*DRACONIAN") ~= nil or
        level(ctx, mutations.MUT_STINGER) > 0 or
        level(ctx, mutations.MUT_ARMOURED_TAIL) > 0 or
        level(ctx, mutations.MUT_WEAKNESS_STINGER) > 0 or
        level(ctx, mutations.MUT_MERTAIL) > 0 or
        level(ctx, mutations.MUT_CONSTRICTING_TAIL) > 0
end

function tailslap.available(ctx)
    return has_tail(ctx) and
        level(ctx, mutations.MUT_CONSTRICTING_TAIL) == 0
end

-- Source: melee-attack.cc:AuxTailslap.
function tailslap.describe(ctx)
    local stinger = level(ctx, mutations.MUT_STINGER)
    local armoured = level(ctx, mutations.MUT_ARMOURED_TAIL)
    local weakness = level(ctx, mutations.MUT_WEAKNESS_STINGER)

    return {
        name = "tail-slap",
        verb = "tail-slap",
        base = 6 + math.max(0, stinger * 2 - 1) +
            armoured * 4 + weakness,
    }
end

local function vulnerable_to_weakness(definition)
    for _, holiness in ipairs(definition.holiness or {}) do
        if holiness == holiness_ids.UNDEAD or
            holiness == holiness_ids.NONLIVING then
            return false
        end
    end

    return true
end

function tailslap.on_hit(ctx, target, definition, result)
    if result.damage <= 0 then
        return
    end

    if level(ctx, mutations.MUT_WEAKNESS_STINGER) >= 3 then
        if not vulnerable_to_weakness(definition) then
            return
        end

        local status = ctx:get(target, component.MONSTER_ENFEEBLE)
        local previous = status and status.weak_aut or 0
        local duration = (6 + ctx:random("melee", 9)) * 10
        local next_status = status or {
            weak_aut = 0,
            antimagic_aut = 0,
            blind_aut = 0,
            dazed_aut = 0,
        }

        next_status.weak_aut = math.max(next_status.weak_aut, duration)

        if status then
            ctx:set(target, component.MONSTER_ENFEEBLE, next_status)
        else
            ctx:add(target, component.MONSTER_ENFEEBLE, next_status)
        end

        if previous == 0 then
            ctx:emit("combat", "The " .. definition.name .. " looks weaker.")
        end

        return
    end

    if level(ctx, mutations.MUT_STINGER) > 0 and
        ctx:random("melee", 2) == 0 then
        poison.apply(ctx, target, definition, 1, ctx:player())
    end
end

auxiliary.register(tailslap)

return tailslap
