local items = require("ids.items")
local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local experience_limit = require("policy.character.experience_limit")
local fighter = require("policy.combat.fighter")
local colors = require("policy.presentation.colors")

local view = {}

function view.player(ctx, input)
    local name = input.name or ""
    local species = catalog.get("species", input.species_id)
    local job = catalog.get("jobs", input.job_id)
    local maximum = experience_limit.max_level(ctx, ctx:player())
    local percent = formulas.level_progress(input.total_xp, input.level,
        species.xp, maximum)

    if name == "" then
        name = "Adventurer"
    end

    return {
        player_name = name,
        species_name = species.name,
        character_name = species.name .. " " .. job.name,
        next_level_percent = percent,
    }
end

function view.entity(input)
    local role = input.role
    local kind_id = input.kind_id or ""
    local name = ""
    local glyph = string.byte("?")

    if role == "player" then
        kind_id = "player"
        name = input.player_name or "Adventurer"
        glyph = string.byte("@")
    elseif role == "monster" then
        local monster = catalog.get("monsters", kind_id)
        name = monster.name
        glyph = monster.glyph
    elseif role == "disturbance" then
        name = "disturbance in the air"
        glyph = string.byte("{")
    elseif role == "item" then
        local item = catalog.get("items", kind_id)
        name = item.name
        glyph = item.glyph

        if input.corpse_monster_id and input.corpse_monster_id ~= "" then
            local source = catalog.get("monsters", input.corpse_monster_id)
            name = source.name .. " " .. name
        end
    end

    return { kind_id = kind_id, role = role, name = name, glyph = glyph }
end

function view.inventory_item(input)
    local item = catalog.get("items", input.kind_id)

    return {
        kind_id = input.kind_id,
        name = item.name,
        class = item.class,
        quantity = input.quantity,
        plus = input.plus,
        charges = input.charges,
        ego = input.ego,
        slot = input.slot or "",
    }
end

function view.terrain_color(input)
    if input.detected_item then
        return { fg = colors.green }
    end

    if input.state ~= 2 then
        return { fg = colors.dark_grey }
    end

    if input.glyph == "<" or input.glyph == ">" then
        return { fg = colors.yellow }
    end

    return { fg = colors.light_grey }
end

function view.detected_item()
    -- Source: viewchar.cc, CSET_ASCII item_detected.
    return { glyph = string.byte("{") }
end

function view.entity_color(input)
    if input.role == "player" then
        return { fg = colors.white }
    end

    if input.role == "monster" then
        return { fg = colors.brown }
    end

    if input.role == "item" then
        if input.kind_id == items.CORPSE_BODY then
            return { fg = colors.brown }
        elseif input.kind_id == items.CORPSE_SKELETON then
            return { fg = colors.light_grey }
        end

        return { fg = colors.light_green }
    end

    return { fg = colors.light_grey }
end

function view.run_player(ctx, input)
    return view.player(ctx, input)
end

function view.run_entity(_, input)
    return view.entity(input)
end

function view.run_inventory_item(_, input)
    return view.inventory_item(input)
end

function view.run_terrain_color(_, input)
    return view.terrain_color(input)
end

function view.run_entity_color(_, input)
    return view.entity_color(input)
end

function view.run_defense(ctx)
    local defense = fighter.defense(ctx)

    return {
        ac = defense.ac,
        ev = defense.ev,
        sh = math.floor(defense.shield_class / 2),
    }
end

register.policy({
    id = "presentation.player",
    run = view.run_player,
})

register.policy({
    id = "presentation.entity",
    run = view.run_entity,
})

register.policy({
    id = "presentation.inventory_item",
    run = view.run_inventory_item,
})

register.policy({
    id = "presentation.terrain_color",
    run = view.run_terrain_color,
})

register.policy({
    id = "presentation.entity_color",
    run = view.run_entity_color,
})

register.policy({
    id = "presentation.detected_item",
    run = view.detected_item,
})

register.policy({
    id = "presentation.defense",
    run = view.run_defense,
})

return view
