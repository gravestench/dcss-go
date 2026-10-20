-- Theory of operation: Stronghold starts with one group per subdivision
-- cell. It joins interior cells through long borders, avoiding outer-edge
-- groups and singleton cells that would bridge two established buildings.
-- Unjoined cells later become streets; joined cells become building boxes.
local material = require("policy.generation.layouts.material")

local groups = {}

-- Draw a positive-weight candidate in stable source-cell order.
local function weighted(builder, candidates)
    local total = 0

    for _, candidate in ipairs(candidates) do
        total = total + candidate.weight
    end

    if total == 0 then
        return nil
    end

    local draw = builder:roll(total)

    for _, candidate in ipairs(candidates) do
        if draw < candidate.weight then
            return candidate.value
        end

        draw = draw - candidate.weight
    end
end

-- Every cell starts in its own group, with an ordered incident-border list.
local function initial(cells, edges, bounds)
    local owners = {}
    local active = {}
    local incident = {}

    for index, cell in ipairs(cells) do
        owners[index] = index
        incident[index] = {}
        active[index] = {
            members = { index },
            edge = cell.x1 == bounds.x1 or cell.x2 == bounds.x2 or
                cell.y1 == bounds.y1 or cell.y2 == bounds.y2,
            would_link = false,
        }
    end

    for _, edge in ipairs(edges) do
        incident[edge.first][#incident[edge.first] + 1] = edge
        incident[edge.second][#incident[edge.second] + 1] = edge
    end

    return owners, active, incident
end

-- Source countborders looks only for distinct adjacent groups already
-- larger than one cell. It prevents a new building from joining two others.
local function big_neighbors(cell, owners, active, incident)
    local seen = {}
    local count = 0
    local single

    for _, edge in ipairs(incident[cell]) do
        local other = edge.first == cell and edge.second or edge.first
        local group_id = owners[other]
        local group = active[group_id]

        if #group.members > 1 and not seen[group_id] then
            seen[group_id] = true
            single = group_id
            count = count + 1
        end
    end

    return count, single
end

-- Source wgroup excludes edge groups and would-link groups; otherwise it
-- weights a building by its member count so clusters keep growing.
local function choose_group(builder, active)
    local choices = {}

    for index = 1, #active do
        local group = active[index]

        if group and not group.edge and not group.would_link then
            choices[#choices + 1] = {
                value = index,
                weight = 10 * #group.members,
            }
        end
    end

    return weighted(builder, choices)
end

-- An established building can use any cell with a free border. A lone
-- cell may attach to one established group, but cannot bridge two.
local function cell_weight(cell, owners, active, incident)
    local remaining = 0

    for _, edge in ipairs(incident[cell]) do
        if not edge.style then
            remaining = remaining + 1
        end
    end

    if remaining == 0 then
        return 0
    end

    local group = active[owners[cell]]

    if #group.members > 1 then
        return 10
    end

    local count, link_to = big_neighbors(cell, owners, active, incident)

    if count > 1 then
        group.would_link = true
        return 0
    end

    group.link_to = link_to
    return 10
end

-- Choose one member from a weighted group, preserving the source's cell
-- order instead of iterating a Lua hash table.
local function choose_cell(builder, group, owners, active, incident)
    local choices = {}

    for _, cell in ipairs(group.members) do
        choices[#choices + 1] = {
            value = cell,
            weight = cell_weight(cell, owners, active, incident),
        }
    end

    return weighted(builder, choices)
end

-- A border must fit a room passage and avoid perimeter groups. Internal
-- links are possible at half weight; external links obey would-link rules.
local function border_weight(edge, cell, owners, active, incident)
    local other = edge.first == cell and edge.second or edge.first
    local from_id = owners[cell]
    local to_id = owners[other]
    local from = active[from_id]
    local target = active[to_id]

    if edge.style or edge.length < 3 or target.edge then
        return 0
    end

    if from_id == to_id then
        return 5
    end

    if #from.members > 1 then
        if target.would_link then
            return 0
        end

        local count = big_neighbors(cell, owners, active, incident)

        if count > 1 then
            target.would_link = true
            return 0
        end

        return 10
    end

    if not from.link_to or from.link_to == to_id then
        return 10
    end

    return 0
end

-- Sample one remaining border through the source's weighted callback.
local function choose_border(builder, cell, owners, active, incident)
    local choices = {}

    for _, edge in ipairs(incident[cell]) do
        choices[#choices + 1] = {
            value = edge,
            weight = border_weight(edge, cell, owners, active, incident),
        }
    end

    return weighted(builder, choices)
end

-- Merge the target into the chosen cell's group, retaining its material
-- and stable ID while updating the ownership of every target member.
local function merge(owners, active, from_id, to_id)
    if from_id == to_id then
        return
    end

    local from = active[from_id]
    local target = active[to_id]

    for _, cell in ipairs(target.members) do
        owners[cell] = from_id
        from.members[#from.members + 1] = cell
    end

    active[to_id] = false
end

-- Run up to one hundred source connection attempts. A selected group may
-- have no eligible member or border; that attempt still consumes its draw.
function groups.connect(builder, cells, edges, bounds, room_materials, branch)
    local owners, active, incident = initial(cells, edges, bounds)

    for _ = 1, 100 do
        local group_id = choose_group(builder, active)

        if not group_id then
            break
        end

        local cell = choose_cell(builder, active[group_id],
            owners, active, incident)
        local edge = cell and choose_border(builder,
            cell, owners, active, incident)

        if edge then
            local group = active[owners[cell]]

            if room_materials and not group.material then
                group.material = material.room(builder, branch)
            end

            edge.style = "internal"

            local other = edge.first == cell and edge.second or edge.first

            merge(owners, active, owners[cell], owners[other])
        end
    end

    for index, cell in ipairs(cells) do
        for _, edge in ipairs(incident[index]) do
            if edge.style == "internal" then
                cell.building = true
                break
            end
        end
    end

    return function(index)
        return active[owners[index]]
    end
end

return groups
