local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local fighter = require("policy.combat.fighter")
local colors = require("policy.presentation.colors")

local view = {}

function view.player(input)
    local name = input.name or ""
    local species = catalog.get("species", input.species_id)
    local job = catalog.get("jobs", input.job_id)
    local percent = formulas.level_progress(input.total_xp, input.level, species.xp)

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
    if input.state ~= 2 then
        return { fg = colors.dark_grey }
    end

    if input.glyph == "<" or input.glyph == ">" then
        return { fg = colors.yellow }
    end

    return { fg = colors.light_grey }
end

function view.entity_color(input)
    if input.role == "player" then
        return { fg = colors.white }
    end

    if input.role == "monster" then
        return { fg = colors.brown }
    end

    if input.role == "item" then
        if input.kind_id == "CORPSE_BODY" then
            return { fg = colors.brown }
        elseif input.kind_id == "CORPSE_SKELETON" then
            return { fg = colors.light_grey }
        end

        return { fg = colors.light_green }
    end

    return { fg = colors.light_grey }
end

local function install(name, run)
    register.policy({
        id = name,
        run = function(_, input)
            return run(input)
        end,
    })
end

install("presentation.player", view.player)
install("presentation.entity", view.entity)
install("presentation.inventory_item", view.inventory_item)
install("presentation.terrain_color", view.terrain_color)
install("presentation.entity_color", view.entity_color)

register.policy({
    id = "presentation.defense",
    run = function(ctx)
        local defense = fighter.defense(ctx)

        return {
            ac = defense.ac,
            ev = defense.ev,
            sh = math.floor(defense.shield_class / 2),
        }
    end,
})

return view
