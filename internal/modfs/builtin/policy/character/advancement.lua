local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local spell_records = require("policy.character.spell_records")
local forms = require("policy.magic.effects.forms.player")

local advancement = {}

local stat_fields = {
    str = "strength",
    int = "intelligence",
    dex = "dexterity",
}

local function selected_species(ctx, actor)
    local player = ctx:get(actor, "core.player")

    if not player then
        error("player has no selected species")
    end

    return catalog.get("species", player.species_id)
end

local function increase_stat(attributes, id, amount)
    local field = stat_fields[id]

    if not field then
        error("unsupported level-up stat " .. tostring(id))
    end

    attributes[field] = attributes[field] + amount
end

function advancement.apply_level(ctx, actor, level, species)
    local progress = ctx:get(actor, "core.progression")
    local attributes = ctx:get(actor, "core.attributes")
    local skills = ctx:get(actor, "core.skills")
    local health = ctx:get(actor, "core.health")
    local magic = ctx:get(actor, "core.magic")
    local regeneration = ctx:get(actor, "core.regeneration")

    if not attributes or not skills or not health or not magic or not regeneration or
        health.max <= 0 or magic.max < 0 then
        error("player lacks advancement components")
    end

    local drain = ctx:get(actor, "status.drain")
    local drain_loss = drain and drain.amount or 0
    local base_hp = math.max(1,
        formulas.max_hp(level, species, skills.entries) - drain_loss)
    local next_hp = forms.scale_hp(ctx, actor, base_hp)
    local next_mp = formulas.max_mp(level, species, skills.entries)
    local stat_frequency = species.levelup_stat_frequency
    local stat_options = type(species.levelup_stats) == "table" and species.levelup_stats or {}

    if stat_frequency > 0 and #stat_options > 0 and level % stat_frequency == 0 then
        local index = ctx:random("level", #stat_options) + 1
        increase_stat(attributes, stat_options[index], 1)
    end

    formulas.rescale_health(health, regeneration, next_hp)

    if magic.max > 0 then
        magic.current = math.floor(magic.current * next_mp / magic.max)
    else
        magic.current = next_mp
    end

    magic.max = next_mp
    progress.level = level
    ctx:set(actor, "core.attributes", attributes)
    ctx:set(actor, "core.health", health)
    ctx:set(actor, "core.magic", magic)
    ctx:set(actor, "core.regeneration", regeneration)
    ctx:set(actor, "core.progression", progress)
    spell_records.grant_scheduled(ctx, actor, level)

    local message = "You have reached level " .. level .. "!"

    if level == 27 then
        message = "You have reached level 27, the final one!"
    end

    ctx:emit("level-up", message)
end

function advancement.advance(ctx, actor)
    local progress = ctx:get(actor, "core.progression")

    if not progress or progress.level < 1 or progress.level > 27 then
        error("player has invalid advancement state")
    end

    if progress.pending_stat_level ~= 0 then
        return
    end

    local species = selected_species(ctx, actor)

    while progress.level < 27 do
        local next_level = progress.level + 1
        local needed = formulas.experience_needed(next_level, species.xp)

        if progress.total_xp < needed then
            break
        end

        if formulas.needs_manual_stat(next_level) then
            progress.pending_stat_level = next_level
            ctx:set(actor, "core.progression", progress)
            ctx:emit("stat-choice", "Your experience leads to an increase in your attributes!")
            break
        end

        advancement.apply_level(ctx, actor, next_level, species)
        progress.level = next_level
    end
end

function advancement.choose_stat(ctx, actor, id)
    local progress = ctx:get(actor, "core.progression")

    if not progress or progress.pending_stat_level ~= progress.level + 1 then
        error("no stat choice is pending")
    end

    local attributes = ctx:get(actor, "core.attributes")

    if not attributes then
        error("player has no attributes")
    end

    if not stat_fields[id] then
        return { message = "Choose Strength, Intelligence, or Dexterity." }
    end

    increase_stat(attributes, id, 2)
    local next_level = progress.pending_stat_level
    progress.pending_stat_level = 0
    ctx:set(actor, "core.attributes", attributes)
    ctx:set(actor, "core.progression", progress)
    local species = selected_species(ctx, actor)
    advancement.apply_level(ctx, actor, next_level, species)
    advancement.advance(ctx, actor)

    return { chosen = true }
end

function advancement.choose_stat_policy(ctx, input)
    return advancement.choose_stat(ctx, ctx:player(), input.stat)
end

register.policy({
    id = "character.choose_stat",
    run = advancement.choose_stat_policy,
})

return advancement
