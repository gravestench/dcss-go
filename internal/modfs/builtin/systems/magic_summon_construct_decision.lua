local spells = require("ids.spells")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local prism = require("policy.magic.effects.summons.fulminant_prism")
local foxfire = require("policy.magic.effects.summons.foxfire")
local ball_lightning = require("policy.magic.effects.summons.ball_lightning")
local servitor = require("policy.magic.effects.summons.spellforged_servitor")
local spire = require("policy.magic.effects.summons.lightning_spire")
local tentacle = require("policy.magic.effects.summons.tentacle")
local vortex = require("policy.magic.effects.summons.fire_vortex")

local actions = {
    [spells.SPELL_FULMINANT_PRISM] = prism.act,
    [spells.SPELL_FOXFIRE] = foxfire.act,
    [spells.SPELL_CONJURE_BALL_LIGHTNING] = ball_lightning.act,
    [spells.SPELL_SPELLFORGED_SERVITOR] = servitor.act,
    [spells.SPELL_SUMMON_LIGHTNING_SPIRE] = spire.act,
    [spells.SPELL_FIRE_STORM] = vortex.act,
}

local function follow_owner(ctx, state, position)
    local owner = ctx:get(state.owner, component.POSITION)

    if not owner or owner.level_id ~= position.level_id or
        math.max(math.abs(owner.x - position.x), math.abs(owner.y - position.y)) <= 1 then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local dx, dy, found = ctx:route_step(position.level_id,
        position.x, position.y, owner.x, owner.y, state.owner)

    if found and ctx:walkable(position.level_id, position.x + dx, position.y + dy) and
        not ctx:actor_at(position.level_id, position.x + dx, position.y + dy) then
        return { kind = intent_ids.MONSTER_MOVE, dx = dx, dy = dy }
    end

    return { kind = intent_ids.MONSTER_WAIT }
end

-- Source: construct turns have their own actions; ordinary allies use
-- monster.decision and the shared movement/combat systems.
local system = {}

function system.update(ctx, entity)
    if ctx:has(entity, component.INTENT) then
        return
    end

    local health = ctx:get(entity, component.HEALTH)
    local position = ctx:get(entity, component.POSITION)

    if not health or health.current <= 0 or not position then
        return
    end

    local state = ctx:get(entity, component.SUMMON)
    local action = actions[state.source_id]
    local intent

    if ctx:has(entity, component.SUMMON_SEGMENT) then
        intent = { kind = intent_ids.MONSTER_WAIT }
    elseif state.source_id == spells.SPELL_MALIGN_GATEWAY then
        intent = tentacle.act(ctx, entity, position)
    elseif action then
        intent = action(ctx, entity, position)
    elseif state.source_id == spells.SPELL_BATTLESPHERE then
        intent = follow_owner(ctx, state, position)
    end

    if intent then
        ctx:add(entity, component.INTENT, intent)
    end
end

register.system({
    id = "magic.summon.construct_decision",
    scope = "active",
    query = { component.SUMMON },
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
