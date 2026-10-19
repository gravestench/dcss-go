-- Battlecry and Hunting Call select allied recipients, while Warning Cry
-- only alerts listeners. Boon state and noise propagation stay with their
-- existing ECS and world owners.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local attitudes = require("constants.attitude")
local boons = require("policy.combat.monster_support.boons")
local catalog = require("policy.catalog")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local engulf = require("policy.combat.engulf")
local noise = require("policy.world.noise")
local roll = require("policy.combat.roll")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local silence = require("policy.world.silence")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")
local vision = require("policy.character.vision")

local cries = {}
local sight = 7

-- A muted, water-held, or silenced monster cannot produce a vocal
-- group action, even if its spellbook offered one.
local function silent(ctx, caster, origin)
    if ctx:has(caster, component.MONSTER_MUTE) or
        engulf.silenced(ctx, caster) then
        return true
    end

    return silence.at(ctx, origin.level_id, origin.x, origin.y)
end

-- Source battlecries require a real enemy in no-trans line of sight.
local function visible_foe(ctx, caster, foe, origin)
    local position = foe and ctx:get(foe, component.POSITION)

    if not position or position.level_id ~= origin.level_id or
        not targets.enemy(ctx, caster, foe) then
        return false
    end

    local distance = math.max(math.abs(position.x - origin.x),
        math.abs(position.y - origin.y))

    -- A cry is sound, not a physical projectile. An intervening ally
    -- cannot prevent the caster from seeing the foe it is warning about.
    return distance <= sight and
        ctx:visible_no_trans(origin.level_id, origin.x, origin.y, sight,
            position.x, position.y)
end

-- Confusion, frenzy, paralysis, and petrification prevent a recipient
-- from taking up a cry. Sleep does not: source wakes a buffed sleeper.
local function unable(ctx, ally)
    local confusion = ctx:get(ally, component.MONSTER_CONFUSION)
    local paralysis = ctx:get(ally, component.PARALYSIS)
    local stone = ctx:get(ally, component.MONSTER_STASIS)

    return allegiance.frenzied(ctx, ally) or
        confusion and confusion.remaining_aut > 0 or
        paralysis and paralysis.remaining_aut > 0 or
        stone and stone.petrified_aut > 0
end

-- Existing Might or either movement-speed boon makes a repeat cry useless.
local function already_benefits(ctx, ally, kind)
    if kind == spells.SPELL_BATTLECRY then
        return boons.mighty(ctx, ally)
    end

    return boons.swift_active(ctx, ally) or
        boons.hasted(ctx, ally)
end

-- One recipient must match source genus and temporary alignment and be
-- visible through ordinary opaque geometry within seven cells.
local function eligible(ctx, caster, ally, caster_kind, origin, kind)
    if ally == caster or ally == ctx:player() or
        not targets.aligned(ctx, caster, ally) or
        unable(ctx, ally) or already_benefits(ctx, ally, kind) then
        return false
    end

    local actor = ctx:get(ally, component.ACTOR)
    local position = ctx:get(ally, component.POSITION)
    local health = ctx:get(ally, component.HEALTH)

    if not actor or not position or not health or
        health.current <= 0 or position.level_id ~= origin.level_id then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local distance = math.max(math.abs(position.x - origin.x),
        math.abs(position.y - origin.y))

    return definition.genus_id == caster_kind.genus_id and
        distance <= sight and
        ctx:visible_no_trans(origin.level_id, origin.x, origin.y, sight,
            position.x, position.y)
end

-- Snapshot matching actors before applying boons so a recipient cannot be
-- visited twice and a planning pass consumes no RNG or world writes.
local function recipients(ctx, caster, kind, origin)
    local actor = ctx:get(caster, component.ACTOR)
    local caster_kind = catalog.get("monsters", actor.kind_id)
    local selected = {}

    for _, other in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if eligible(ctx, caster, other, caster_kind, origin, kind) then
            selected[#selected + 1] = other
        end
    end

    return selected
end

-- Source random_range(12, 20) multiplies one stochastic 100/speed draw.
-- Example: a speed-ten ally gains at least 120 aut of Might or Swift.
local function duration(ctx, ally)
    local actor = ctx:get(ally, component.ACTOR)
    local speed = actor.speed < 1 and 10 or
        math.min(100, actor.speed)
    local turns = 12 + roll.spell(ctx, 9)

    return turns * roll.random_divide(ctx, 100, speed,
        "monster_spell")
end

-- Source announcements describe only recipients the player can actually
-- see; a distant cry must not reveal an unseen group or its size.
local function seen_by_player(ctx, monster)
    local player = ctx:player()
    local eye = player and ctx:get(player, component.POSITION)
    local position = ctx:get(monster, component.POSITION)

    if not eye or not position or eye.level_id ~= position.level_id then
        return false
    end

    local reach = vision.radius(ctx, player)
    local distance = math.max(math.abs(position.x - eye.x),
        math.abs(position.y - eye.y))

    if distance > reach or
        not ctx:visible(eye.level_id, eye.x, eye.y, reach,
            position.x, position.y) then
        return false
    end

    return senses.perceive(ctx, player, monster, true) == "visible"
end

-- Example: cries.plan(ctx, orc_knight, player, SPELL_BATTLECRY)
-- declines an already mighty group before spending an action or RNG draw.
function cries.plan(ctx, caster, foe, kind)
    if kind ~= spells.SPELL_BATTLECRY and
        kind ~= spells.SPELL_HUNTING_CALL then
        error("unsupported monster battlecry " .. tostring(kind))
    end

    local origin = ctx:get(caster, component.POSITION)

    if not origin or silent(ctx, caster, origin) or
        not visible_foe(ctx, caster, foe, origin) or
        #recipients(ctx, caster, kind, origin) == 0 then
        return nil
    end

    return self_target.plan(caster)
end

-- Grant source Might or Swift, disturb affected sleepers, then make one
-- audible field for nearby monsters and one readable announcement.
function cries.resolve(ctx, caster, plan, kind)
    self_target.require_caster(plan, caster)

    local origin = ctx:get(caster, component.POSITION)
    local affected = recipients(ctx, caster, kind, origin)

    if #affected == 0 then
        return
    end

    for _, ally in ipairs(affected) do
        local remaining = duration(ctx, ally)

        if kind == spells.SPELL_BATTLECRY then
            boons.might(ctx, ally, remaining)
        else
            boons.swift(ctx, ally, remaining)
        end

        stasis.wake_hibernating(ctx, ally)
    end

    noise.emit(ctx, origin, sight, caster)

    local seen = {}

    for _, ally in ipairs(affected) do
        if seen_by_player(ctx, ally) then
            seen[#seen + 1] = ally
        end
    end

    if #seen == 1 then
        local action = kind == spells.SPELL_BATTLECRY and
            "goes into a battle-frenzy!" or "picks up the pace!"

        ctx:emit("spell", "The " .. display.name(ctx, seen[1]) ..
            " " .. action)
    elseif #seen > 1 then
        local action = kind == spells.SPELL_BATTLECRY and
            "go into a battle-frenzy!" or "pick up the pace!"

        ctx:emit("spell", "The nearby allies " .. action)
    end
end

-- Warning Cry is useful to hostile casters even without an ally to buff.
function cries.warning_plan(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)

    if not origin or
        targets.attitude(ctx, caster) == attitudes.FRIENDLY or
        silent(ctx, caster, origin) then
        return nil
    end

    return self_target.plan(caster)
end

-- Source Warning Cry's spell declaration gives it loudness 25; sound is
-- the effect, so it must reach the production hearing and awareness owner.
-- Example: cries.warning(ctx, caster, plan) redirects a wandering listener.
function cries.warning(ctx, caster, plan)
    self_target.require_caster(plan, caster)

    local origin = ctx:get(caster, component.POSITION)

    local _, heard = noise.emit(ctx, origin, 25, caster)

    if seen_by_player(ctx, caster) then
        ctx:emit("sound", "The " .. display.name(ctx, caster) ..
            " lets out a warning cry!")
    elseif heard then
        ctx:emit("sound", "You hear a warning cry!")
    end
end

return cries
