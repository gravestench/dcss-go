-- Source: ouch.cc:_maybe_summon_demonic_guardian and
-- mutation.cc:check_demonic_guardian. The damage reaction owns the trigger;
-- the player ECS component owns its cooldown across saves.
local allies = require("policy.character.allies")
local causes = require("constants.damage_causes")
local categories = require("constants.catalog")
local component = require("constants.component")
local levels = require("policy.mutations.levels")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local order = require("constants.damage_reaction_order")
local reactions = require("policy.combat.player_damage_reactions")
local summons = require("policy.magic.effects.summons.common")

local guardian = {}

local tiers = {
    {
        monsters.MONS_QUASIT,
        monsters.MONS_WHITE_IMP,
        monsters.MONS_UFETUBUS,
        monsters.MONS_IRON_IMP,
        monsters.MONS_SHADOW_IMP,
    },

    {
        monsters.MONS_ORANGE_DEMON,
        monsters.MONS_ICE_DEVIL,
        monsters.MONS_RUST_DEVIL,
        monsters.MONS_HELLWING,
    },

    {
        monsters.MONS_SOUL_EATER,
        monsters.MONS_SMOKE_DEMON,
        monsters.MONS_SIXFIRHY,
        monsters.MONS_SUN_DEMON,
    },

    {
        monsters.MONS_BALRUG,
        monsters.MONS_REAPER,
        monsters.MONS_LOROCYPROCA,
        monsters.MONS_CACODEMON,
        monsters.MONS_HELL_BEAST,
    },

    {
        monsters.MONS_EXECUTIONER,
        monsters.MONS_HELL_SENTINEL,
        monsters.MONS_BRIMSTONE_FIEND,
    },
}

function guardian.tick(ctx, player, aut)
    local state = ctx:get(player, component.DEMONIC_GUARDIAN)

    if not state or state.cooldown_aut == 0 then
        return
    end

    state.cooldown_aut = math.max(0, state.cooldown_aut - aut)
    ctx:set(player, component.DEMONIC_GUARDIAN, state)
end

local function choose(ctx, player, level)
    local progression = ctx:get(player, component.PROGRESSION)

    if not progression then
        error("demonic guardian requires player progression")
    end

    local tier = level + summons.divide(ctx, progression.level - 9, 9)
    tier = math.max(1, math.min(#tiers, tier))

    local choices = tiers[tier]

    return choices[ctx:random("mutation", #choices) + 1]
end

function guardian.on_damage(ctx, player, damage, cause)
    local level = levels.effective(ctx, player,
        mutations.MUT_DEMONIC_GUARDIAN)

    if level == 0 or cause == causes.POISON or
        allies.forbidden(ctx, player) then
        return
    end

    local state = ctx:get(player, component.DEMONIC_GUARDIAN)

    if state and state.cooldown_aut > 0 then
        return
    end

    local health = ctx:get(player, component.HEALTH)

    if not health or health.max <= 0 then
        error("demonic guardian requires player health")
    end

    -- Source evaluates the damage chance before the two health shortcuts.
    local chance = ctx:random("mutation", health.max) < damage

    if not chance and damage <= health.max / 2 and
        health.current * 5 >= health.max then
        return
    end

    local kind = choose(ctx, player, level)
    local summoned = summons.spawn(ctx, player,
        mutations.MUT_DEMONIC_GUARDIAN, kind, 2, 1, {
            source_category = categories.MUTATIONS,
        })

    if not summoned then
        return
    end

    local cooldown = (level + ctx:random("mutation", 20)) * 10
    local next_state = {
        cooldown_aut = cooldown,
    }

    if state then
        ctx:set(player, component.DEMONIC_GUARDIAN, next_state)
    else
        ctx:add(player, component.DEMONIC_GUARDIAN, next_state)
    end

    ctx:emit("mutation", "A demonic guardian appears!")
end

reactions.add(mutations.MUT_DEMONIC_GUARDIAN,
    order.DEMONIC_GUARDIAN, guardian.on_damage)

return guardian
