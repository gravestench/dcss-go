local abilities = require("ids.abilities")
local blink = require("policy.combat.dispersal")
local common = require("policy.magic.effects.translocation.common")
local component = require("constants.component")
local failure = require("policy.abilities.failure")
local flags = require("constants.monster_flags")
local groups = require("constants.monster_groups")
local items = require("ids.items")
local mass = require("policy.magic.effects.statuses.mass_enchantment")
local mutations = require("ids.mutations")
local net = require("policy.combat.net")
local registry = require("policy.abilities.registry")
local roll = require("policy.combat.roll")
local slow = require("policy.combat.monster_slow")
local silence = require("policy.world.silence")
local targets = require("policy.ai.targets")
local teleport = require("policy.magic.effects.zaps.teleport_other")
local vision = require("policy.character.vision")

local chaos = {}

-- Limit the word to visible enemies that can move; tentacles, conjurations,
-- and stationary monsters would make the displacement effect incoherent.
local function eligible(ctx, player, monster, origin)
    return not groups.tentacles[monster.actor.kind_id] and
        not common.flag(monster.definition, flags.STATIONARY) and
        not common.flag(monster.definition, flags.CONJURED) and
        targets.enemy(ctx, player, monster.entity) and
        ctx:visible(origin.level_id, origin.x, origin.y,
            vision.radius(ctx, player),
            monster.position.x, monster.position.y)
end

-- A prompt is needed only when no eligible enemy is visible to the player.
function chaos.confirmation_needed(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    for _, monster in ipairs(common.monsters(ctx, origin.level_id)) do
        if eligible(ctx, player, monster, origin) then
            return false
        end
    end

    return true
end

-- State the no-visible-target case explicitly so a forced cast cannot look
-- like an accidental silent failure after the player accepts it.
function chaos.confirmation_message()
    return "You cannot see any enemies that you can affect. " ..
        "Speak a word of chaos anyway?"
end

-- Check cooldown, silence, and MP before asking for confirmation; impossible
-- casts should return a free reason instead of opening a prompt.
function chaos.prepare(ctx, player, input)
    local cooldown = ctx:get(player, component.ABILITY_COOLDOWNS)

    if cooldown and cooldown.word_of_chaos_aut > 0 then
        return "You cannot speak another word of chaos yet."
    end

    if silence.actor(ctx, player) then
        return "You cannot speak a word of chaos while silenced."
    end

    local magic = ctx:get(player, component.MAGIC)

    if not magic or magic.current < 6 then
        return "You do not have enough magic."
    end

    if chaos.confirmation_needed(ctx, player) and not input.forced then
        return chaos.confirmation_message()
    end

    return nil
end

-- Apply the post-cast max-HP drain as an ECS status while preserving at least
-- one max HP, so repeated casts remain savable and nonfatal by themselves.
local function drain_player(ctx, player)
    local health = ctx:get(player, component.HEALTH)
    local old = ctx:get(player, "status.drain")
    local state = old or { amount = 0 }
    local real_max = health.max + state.amount
    local loss = 1 + roll.random_divide(ctx, 50 * real_max, 750)

    loss = math.min(loss, health.max - 1)
    state.amount = state.amount + loss
    health.max = health.max - loss
    health.current = math.min(health.current, health.max)
    ctx:set(player, component.HEALTH, health)

    if old then
        ctx:set(player, "status.drain", state)
    else
        ctx:add(player, "status.drain", state)
    end

    ctx:emit("mutation", "You feel drained.")
end

-- Create a real net item at the monster's position before applying Held;
-- the shared net rules then own escape and item cleanup.
function chaos.ensnare(ctx, monster, definition)
    if not net.can_hold(definition) or ctx:has(monster, component.HELD) then
        return false
    end

    local position = ctx:get(monster, component.POSITION)
    local net_item = ctx:create()

    ctx:add(net_item, component.ITEM, {
        kind_id = items.MI_THROWING_NET,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(net_item, component.POSITION, position)

    return net.catch(ctx, monster, net_item, definition)
end

-- The target's outcome is applied before the next visible monster is considered.
local function affect_monster(ctx, player, monster, power)
    if teleport.no_tele(monster.actor, monster.definition,
        ctx, monster.entity) then
        return
    end

    blink.blink(ctx, player, monster.entity, monster.definition)

    if ctx:random("mutation", 500) < power then
        chaos.ensnare(ctx, monster.entity, monster.definition)
    end

    if ctx:random("mutation", 500) < power then
        slow.apply(ctx, monster.entity, monster.definition)
    end

    if ctx:random("mutation", 500) < power then
        mass.apply_innate_fear(ctx, monster.entity, monster.definition)
    end
end

-- Shuffle before applying effects so entity query order cannot favour an earlier monster under the same RNG stream.
function chaos.shuffle(ctx, monsters)
    for index = #monsters, 2, -1 do
        local chosen = ctx:random("mutation", index) + 1
        monsters[index], monsters[chosen] =
            monsters[chosen], monsters[index]
    end

    return monsters
end

-- Example: a successful Word moves each visible eligible monster, then spends MP and writes its cooldown.
-- Resolve failure before selecting targets, then collect eligible monsters
-- from current ECS positions so movement cannot change this cast's target set.
function chaos.resolve(ctx, player)
    if failure.roll(ctx, player) then
        ctx:emit("mutation", "You fail to speak a word of chaos.")
        return
    end

    local origin = ctx:get(player, component.POSITION)
    local progression = ctx:get(player, component.PROGRESSION)
    local power = 40 + progression.level * 6

    ctx:emit("mutation", "You speak a word of chaos!")

    local selected = {}

    for _, monster in ipairs(common.monsters(ctx, origin.level_id)) do
        if eligible(ctx, player, monster, origin) then
            selected[#selected + 1] = monster
        end
    end

    for _, monster in ipairs(chaos.shuffle(ctx, selected)) do
        affect_monster(ctx, player, monster, power)
    end

    local magic = ctx:get(player, component.MAGIC)
    magic.current = magic.current - 6
    ctx:set(player, component.MAGIC, magic)

    local cooldown = ctx:get(player, component.ABILITY_COOLDOWNS) or {
        hop_aut = 0,
        word_of_chaos_aut = 0,
    }

    cooldown.word_of_chaos_aut = (15 + ctx:random("mutation", 10)) * 10

    if ctx:has(player, component.ABILITY_COOLDOWNS) then
        ctx:set(player, component.ABILITY_COOLDOWNS, cooldown)
    else
        ctx:add(player, component.ABILITY_COOLDOWNS, cooldown)
    end

    drain_player(ctx, player)
end

registry.add(abilities.WORD_OF_CHAOS, {
    mutation_id = mutations.MUT_WORD_OF_CHAOS,
    name = "Word of Chaos",
    prepare = chaos.prepare,
    confirmation_needed = chaos.confirmation_needed,
    confirmation_message = chaos.confirmation_message,
    resolve = chaos.resolve,
})

return chaos
