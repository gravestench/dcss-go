local roll = require("policy.combat.roll")
local fighter = require("policy.combat.fighter")
local poison = require("policy.combat.monster_poison")
local slow = require("policy.combat.monster_slow")
local dispersal = require("policy.combat.dispersal")
local chaos_missile = require("policy.combat.chaos_missile")
local chaos_effects = require(
    "policy.combat.monster_target_brands.chaos_effects")
local confusion = require(
    "policy.magic.effects.statuses.confusing_touch")
local launcher_flame = require("policy.combat.launcher_brands.flaming")
local launcher_frost = require("policy.combat.launcher_brands.freezing")
local monster_enchant = require("policy.combat.monster_enchant")
local allegiance = require(
    "policy.magic.effects.statuses.monster_allegiance")
local missile_egos = require("constants.missile_egos")
local silver = require("policy.combat.monster_missile_egos.silver")
local item_ids = require("ids.items")
local skills = require("ids.skills")

local effects = {}

-- Example: with poisoned dart hit,
-- effects.missile(ctx, ego, missile, monster, defender, damage, remaining_hp) -> ego damage and poison handling
-- Dispatch a missile ego only after base damage, preserving its remaining-HP contact context.
function effects.missile(ctx, ego, missile, monster, defender, damage, remaining_hp)
    -- Chaos chooses a fresh ordinary missile ego after this particular
    -- contact. The item itself stays Chaos for its next shot or save.
    if ego == missile_egos.CHAOS then
        ego = chaos_missile.choose(ctx, monster)
    end

    if missile.id == item_ids.MI_DART then
        local power = fighter.skill(ctx, skills.SK_THROWING, 1)

        if ego == missile_egos.POISONED then
            damage = roll.melee(ctx, 3 + power * 2)
        elseif ego == missile_egos.CURARE then
            damage = 2
        else
            damage = 5 + roll.melee(ctx, power)
        end
    end

    if ego == "" then
        return 0
    end

    if ego == missile_egos.POISONED then
        local levels = 0

        if missile.id == item_ids.MI_DART then
            -- ranged-attack.cc: player poison darts carry duration
            -- power rather than ordinary hit-point damage.
            levels = damage
        elseif roll.melee(ctx, 4) ~= 0 then
            levels = 6 + roll.melee(ctx, 8) +
                roll.melee(ctx, math.floor(damage * 3 / 2))
        end

        poison.apply(ctx, monster, defender, levels, ctx:player())

        return 0
    end

    if ego == missile_egos.CURARE then
        -- beam.cc poisons, deals 2d6 asphyxiation damage, then
        -- slows a surviving non-resistant monster.
        if not poison.apply(ctx, monster, defender, 2, ctx:player()) then
            return 0
        end

        local extra = 2 + roll.melee(ctx, 6) + roll.melee(ctx, 6)
        ctx:emit("combat", "The " .. defender.name .. " convulses.")

        if remaining_hp > extra then
            slow.apply(ctx, monster, defender)
        end

        return extra
    end

    if ego == missile_egos.DISPERSAL then
        if damage > 0 and remaining_hp > 0 then
            dispersal.blink(ctx, ctx:player(), monster, defender)
        end

        return 0
    end

    if ego == missile_egos.SILVER then
        return silver.monster_bonus(ctx, monster, defender, damage)
    end

    if ego == missile_egos.FLAME or ego == missile_egos.FROST then
        local effect = ego == missile_egos.FLAME and
            launcher_flame or launcher_frost
        local extra, message = effect.apply(ctx,
            missile, defender, damage)

        if message then
            ctx:emit("combat", message)
        end

        return extra or 0
    end

    if ego == missile_egos.BLINDING then
        monster_enchant.blind(ctx, monster, defender)
        confusion.apply_turns(ctx, monster, defender,
            math.floor(damage / 3))

        return 0
    end

    if ego == missile_egos.FRENZY then
        if not allegiance.frenzied(ctx, monster) then
            allegiance.start_berserk(ctx, monster)
        end

        return 0
    end

    if ego == missile_egos.CHAOS then
        chaos_effects.apply(ctx, {
            defender = monster,
            definition = defender,
            damage_done = damage,
        })

        return 0
    end

    error("unsupported missile ego " .. tostring(ego))
end

return effects
