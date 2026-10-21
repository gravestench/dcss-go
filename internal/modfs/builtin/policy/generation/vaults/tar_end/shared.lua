-- Tartarus end maps retain their source script sites in named handlers.
local branches = require("ids.branches")
local monsters = require("ids.monsters")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")
local serpent = require("policy.generation.hell.serpent")

local handler = {}

-- One persistent Hell-branch choice and unique history govern the D glyph.
function handler.serpent_of_hell(api)
    serpent.setup(api, {
        glyph = "D",
        branch_id = branches.BRANCH_TARTARUS,
        monster_id = monsters.MONS_SERPENT_OF_HELL,
    })
end

-- Source tar_dig_maze visits neighbors in this order, using reservoir
-- sampling at every step. Its local cells are edited before NSUBST runs.
local offsets = {
    { x = 2, y = 0 },
    { x = -2, y = 0 },
    { x = 0, y = 2 },
    { x = 0, y = -2 },
}

local function dig(api, x, y, width, height)
    -- Preserve the source depth-first walk and its random draw order with
    -- explicit frames. A full end-floor maze is deeper than the embedded
    -- Lua VM's call stack, even though the source used recursion.
    local frames = {
        { x = x, y = y, passes = 0 },
    }

    while #frames > 0 do
        local frame = frames[#frames]
        local count = 0
        local next_x
        local next_y

        for _, delta in ipairs(offsets) do
            local candidate_x = frame.x + delta.x
            local candidate_y = frame.y + delta.y

            if candidate_x >= 0 and candidate_y >= 0 and
                candidate_x < width and candidate_y < height then
                local glyph = api:cell(candidate_x, candidate_y)

                if glyph ~= "." and glyph ~= " " and
                    glyph ~= "$" and glyph ~= "L" then
                    count = count + 1

                    if api:roll(count) == 0 then
                        next_x = candidate_x
                        next_y = candidate_y
                    end
                end
            end
        end

        if count == 0 then
            if frame.passes == 0 then
                api:set_cell(frame.x, frame.y, "L")
            end

            frames[#frames] = nil
        else
            local middle_x = frame.x
            local middle_y = frame.y

            if next_y == frame.y then
                middle_x = next_x < frame.x and next_x + 1 or next_x - 1
            else
                middle_y = next_y < frame.y and next_y + 1 or next_y - 1
            end

            frame.passes = frame.passes + 1
            api:set_cell(middle_x, middle_y, ".")
            api:set_cell(next_x, next_y, ".")
            frames[#frames + 1] = {
                x = next_x,
                y = next_y,
                passes = 0,
            }
        end
    end
end

function handler.dig_mu_maze(api)
    local width, height = api:map_size()

    dig(api, 0, 0, width, height)
end

function handler.dig_grunt_maze(api)
    local width, height = api:map_size()

    dig(api, 9, 21, width, height)
end

-- The source selects one through six nested rings with one layout draw.
function handler.decor_pillar(api)
    local size = api:roll(6) + 1
    local rings = {
        { glyph = "A", threshold = 2 },
        { glyph = "B", threshold = 3 },
        { glyph = "C", threshold = 4 },
        { glyph = "D", threshold = 5 },
        { glyph = "E", threshold = 6 },
    }

    for _, ring in ipairs(rings) do
        if size >= ring.threshold then
            api:emit(directives.SUBST, ring.glyph .. " = x")
        else
            api:emit(directives.CLEAR, ring.glyph)
        end
    end
end

-- minmay's encompass map asks for permanent rock beyond its own bounds.
function handler.permarock_border(api)
    api:record(effects.BORDER_FILL, {
        style = fill.PERMAROCK_WALL,
    })
end

return handler
