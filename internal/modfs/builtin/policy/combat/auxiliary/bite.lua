local auxiliary = require("policy.combat.auxiliary")
local attacks = require("constants.auxiliary_attacks")
local component = require("constants.component")
local damage = require("policy.magic.damage")
local enchant = require("policy.combat.monster_enchant")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local books = require("ids.monster_spellbooks")
local resistances = require("constants.resistance_ids")
local roll = require("policy.combat.roll")
local monster_stats = require("policy.combat.monster_stats")

local bite = {
    id = attacks.BITE.id,
    order = attacks.BITE.order,
    mutation_ids = {
        mutations.MUT_FANGS,
        mutations.MUT_ACIDIC_BITE,
        mutations.MUT_ANTIMAGIC_BITE,
    },
}

local function level(ctx, id)
    return levels.effective(ctx, ctx:player(), id)
end

function bite.available(ctx)
    return level(ctx, mutations.MUT_FANGS) > 0 or
        level(ctx, mutations.MUT_ACIDIC_BITE) > 0 or
        level(ctx, mutations.MUT_ANTIMAGIC_BITE) > 0
end

function bite.chance(ctx)
    return level(ctx, mutations.MUT_ANTIMAGIC_BITE) > 0 and 100 or 40
end

-- Source: melee-attack.cc:AuxBite. Antimagic adds approximately one third
-- of the player's hit dice before the shared auxiliary damage roll.
function bite.describe(ctx, input)
    local base = 1 + level(ctx, mutations.MUT_FANGS) * 2

    if level(ctx, mutations.MUT_ANTIMAGIC_BITE) > 0 then
        base = base + roll.random_divide(ctx, input.level, 3)
    end

    return {
        name = "bite",
        verb = "bite",
        base = base,
    }
end

local function acid_splash(ctx, target, definition)
    local raw = 2 + roll.melee(ctx, 4) + roll.melee(ctx, 4)
    local extra = damage.monster_elemental(ctx, target, raw,
        resistances.ACID)

    if extra > 0 then
        ctx:emit("combat", "The " .. definition.name ..
            " is splashed with acid.")
    end

    enchant.corrode(ctx, target, definition)

    return extra
end

local function drain_magic(ctx, target, definition, dealt)
    if definition.spellbook_id ~= books.MST_NO_SPELLS then
        local status = ctx:get(target, component.MONSTER_ENFEEBLE)
        local next_status = status or {
            weak_aut = 0,
            antimagic_aut = 0,
            blind_aut = 0,
            dazed_aut = 0,
        }
        local duration = roll.random_divide(ctx, dealt * 32,
            monster_stats.hit_dice(ctx, target, definition))

        duration = roll.melee(ctx, duration + 1) * 10
        next_status.antimagic_aut = math.max(next_status.antimagic_aut,
            duration)

        if status then
            ctx:set(target, component.MONSTER_ENFEEBLE, next_status)
        else
            ctx:add(target, component.MONSTER_ENFEEBLE, next_status)
        end
    end

    local magic = ctx:get(ctx:player(), component.MAGIC)

    if not magic or magic.max <= 0 or magic.current >= magic.max or
        ctx:has(target, component.SUMMON) then
        return
    end

    local rolled = 1 + roll.melee(ctx, dealt * 2)
    local gained = math.floor((1.25 - magic.current / magic.max) * rolled)

    if gained > 0 then
        magic.current = math.min(magic.max, magic.current + gained)
        ctx:set(ctx:player(), component.MAGIC, magic)
        ctx:emit("combat", "You feel invigorated.")
    end
end

function bite.on_hit(ctx, target, definition, result)
    if result.damage <= 0 then
        return 0
    end

    if level(ctx, mutations.MUT_ANTIMAGIC_BITE) > 0 then
        drain_magic(ctx, target, definition, result.damage)

        return 0
    end

    if level(ctx, mutations.MUT_ACIDIC_BITE) > 0 then
        return acid_splash(ctx, target, definition)
    end

    return 0
end

auxiliary.register(bite)

return bite
