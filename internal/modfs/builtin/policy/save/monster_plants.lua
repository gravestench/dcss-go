-- Source plant summons store more links than the generic summon record.
-- Validate those links at save and restore so a broken vine chain or spore
-- cannot survive as an actor with an unresolvable source relationship.
local component = require("constants.component")
local categories = require("constants.catalog")
local attitudes = require("constants.attitude")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local plants = {}

-- A vine head must be a summon of its caster, with a saved tree anchor.
local function validate_vine(ctx, entity, actor, summon, position)
    local vine = ctx:get(entity, component.MONSTER_VINE)

    if not vine then
        return
    end

    if actor.kind_id ~= monsters.MONS_SNAPLASHER_VINE or
        summon.source_id ~= spells.SPELL_AWAKEN_VINES or
        not ctx:has(summon.owner, component.ACTOR) or
        math.max(math.abs(position.x - vine.anchor_x),
            math.abs(position.y - vine.anchor_y)) > 8 then
        error("summoned vine has an invalid caster or tree anchor")
    end
end

-- Every connector must point at a living head with the same caster,
-- source spell, level, and expiry. Its index identifies the chain cell.
local function validate_segment(ctx, entity, actor, summon, position)
    local segment = ctx:get(entity,
        component.MONSTER_VINE_SEGMENT)

    if not segment then
        return
    end

    local head = ctx:get(segment.head, component.MONSTER_VINE)
    local head_actor = ctx:get(segment.head, component.ACTOR)
    local head_summon = ctx:get(segment.head, component.SUMMON)
    local head_position = ctx:get(segment.head, component.POSITION)

    if actor.kind_id ~= monsters.MONS_SNAPLASHER_VINE_SEGMENT or
        summon.source_id ~= spells.SPELL_AWAKEN_VINES or
        segment.index < 1 or segment.index > 7 or not head or
        not head_actor or
        head_actor.kind_id ~= monsters.MONS_SNAPLASHER_VINE or
        not head_summon or head_summon.owner ~= summon.owner or
        head_summon.expires_aut ~= summon.expires_aut or
        not head_position or
        head_position.level_id ~= position.level_id then
        error("summoned vine segment has an invalid head link")
    end
end

-- A spore is a one-use bomb. Sporulate creates spell-owned spores, while
-- Fedhas wrath animates a corpse into a hostile player-targeting god spore.
-- Either source must disappear after its one explosion has fired.
local function validate_spore(ctx, entity, actor, summon)
    local state = ctx:get(entity, component.MONSTER_SPORE)
    local spell_source = summon.source_category == categories.SPELLS and
        summon.source_id == spells.SPELL_SPORULATE
    local fedhas_source = summon.source_category == categories.GODS and
        summon.source_id == gods.FEDHAS and
        summon.attitude == attitudes.HOSTILE and
        summon.owner == ctx:player() and
        state and state.target == summon.owner

    if state and (actor.kind_id ~= monsters.MONS_BALLISTOMYCETE_SPORE or
        not spell_source and not fedhas_source or
        state.exploded) then
        error("summoned spore has an invalid explosion state")
    end
end

-- Each specialized record checks only the invariant it owns; ordinary
-- summons pass through without an extra source-specific branch.
function plants.validate(ctx, entity, actor, summon, position)
    validate_vine(ctx, entity, actor, summon, position)
    validate_segment(ctx, entity, actor, summon, position)
    validate_spore(ctx, entity, actor, summon)
end

return plants
