-- Black Mark belongs to the attacking monster, while its three possible
-- consequences reuse the ordinary status and drain owners of the victim.
-- Source: melee-attack.cc:apply_black_mark_effects.
local catalog = require("policy.catalog")
local component = require("constants.component")
local damage = require("policy.magic.damage")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local monster_drain = require("policy.combat.monster_drain")
local player_antimagic = require("policy.combat.brands.antimagic")
local player_drain = require("policy.combat.player_drain")
local player_weakness = require("policy.combat.player_weakness")
local resistance = require("constants.resistance_ids")
local streams = require("constants.rng_streams")

local mark = {}
local WEAKNESS_TURNS = 6
local ANTIMAGIC_AUT_PER_DAMAGE = 8
local COMPLETE_NEGATIVE_RESISTANCE = 3

-- Only live, saved time enables the melee proc; mere component presence
-- cannot make an expired mark active during a turn boundary.
function mark.active(ctx, attacker)
    local state = ctx:get(attacker, component.MONSTER_BLACK_MARK)

    return state ~= nil and state.remaining_aut > 0
end

-- This record ages on its recipient's actions, like other monster boons.
function mark.tick(ctx, attacker, elapsed_aut)
    local state = ctx:get(attacker, component.MONSTER_BLACK_MARK)

    if not state then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        ctx:remove(attacker, component.MONSTER_BLACK_MARK)
    else
        ctx:set(attacker, component.MONSTER_BLACK_MARK, state)
    end
end

-- The selected effect is a named function. Keeping the candidate list free
-- of closures makes the source's eligibility rules easy to audit separately.
local function drain_player_magic(ctx, _, target, amount)
    player_antimagic.apply(ctx, {
        defender = target,
        damage_done = amount,
    })
end

-- Black Mark weakens a player for six turns through the existing owner.
local function weaken_player(ctx, _, target)
    player_weakness.apply(ctx, target, WEAKNESS_TURNS)
end

-- Negative-energy drain keeps its own resistance and damage conversion.
local function drain_player_life(ctx, _, target, amount)
    player_drain.apply(ctx, target, amount,
        streams.MONSTER_SPELL)
end

-- A monster's antimagic duration scales with the melee hit that procced it.
local function drain_monster_magic(ctx, _, target, amount, definition)
    enfeeble.apply_antimagic(ctx, target, definition,
        amount * ANTIMAGIC_AUT_PER_DAMAGE)
end

-- Reuse the existing Weakness duration and resistance checks for monsters.
local function weaken_monster(ctx, _, target, _, definition)
    enfeeble.apply_weak(ctx, target, definition, WEAKNESS_TURNS,
        streams.MONSTER_SPELL)
end

-- The attacker remains the credited source of monster life drain.
local function drain_monster_life(ctx, attacker, target, _, definition)
    monster_drain.apply(ctx, target, definition,
        attacker, streams.MONSTER_SPELL)
end

-- A player defender has MP, weakening, and negative-energy drain owners.
-- Build the source's candidate set before drawing its one selected effect.
local function player_choices(ctx, target)
    local choices = {}
    local magic = ctx:get(target, component.MAGIC)

    if magic and magic.current > 0 then
        choices[#choices + 1] = drain_player_magic
    end

    choices[#choices + 1] = weaken_player

    if damage.player_resistance(ctx, target,
        resistance.NEGATIVE_ENERGY) < COMPLETE_NEGATIVE_RESISTANCE then
        choices[#choices + 1] = drain_player_life
    end

    return choices
end

-- A monster defender may resist individual effects through its definition
-- and equipment. The effect owners retain the actual status rules.
local function monster_choices(ctx, target, definition)
    local choices = {}

    if enfeeble.antimagic_susceptible(ctx, target) then
        choices[#choices + 1] = drain_monster_magic
    end

    if enfeeble.has_attacks(definition) then
        choices[#choices + 1] = weaken_monster
    end

    if monster_drain.resistance(ctx, target,
        definition) < COMPLETE_NEGATIVE_RESISTANCE then
        choices[#choices + 1] = drain_monster_life
    end

    return choices
end

-- A monster mark procs only after positive HP damage to a surviving melee
-- defender. The player's one-in-five mutation gate has a separate owner.
-- Example: a marked orc can choose Weakness after a successful hit.
function mark.after_melee(ctx, attacker, target, amount)
    if amount <= 0 or not mark.active(ctx, attacker) then
        return
    end

    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return
    end

    local choices
    local definition

    if ctx:has(target, component.PLAYER) then
        choices = player_choices(ctx, target)
    else
        local actor = ctx:get(target, component.ACTOR)

        definition = catalog.get("monsters", actor.kind_id)
        choices = monster_choices(ctx, target, definition)
    end

    if #choices == 0 then
        return
    end

    local index = ctx:random(streams.MONSTER_SPELL, #choices) + 1

    choices[index](ctx, attacker, target, amount, definition)
end

return mark
