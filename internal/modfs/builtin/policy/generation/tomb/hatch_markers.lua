-- Named hatch effects are anchored while their source glyph still exists.
-- Later DES substitutions may turn that glyph into a stair or floor; the
-- marker retains its final transformed coordinate for cross-floor linking.
local effects = require("constants.vault_effects")
local names = require("ids.tomb_hatches")

local markers = {}

-- Keep kind and name in typed record arguments for the bundle resolver.
local function mark(api, glyph, kind, name)
    api:record(effects.MARKER, {
        glyph = glyph,
        identity = kind .. ":" .. name,
        hatch_kind = kind,
        hatch_name = name,
    })
end

-- Tomb:1 centre's outgoing hatches enter the Tomb:2 ambush.
function markers.name_tomb2_entry(api)
    mark(api, ">", "name", names.TOMB2_ENTRY)
end

-- The same centre cells can receive Tomb:2's return hatch.
function markers.dest_tomb2_exit(api)
    mark(api, ">", "dest", names.TOMB2_EXIT)
end

-- The first hall landing is a floor cell reached from Tomb:2.
function markers.dest_tomb1_hall_entry(api)
    mark(api, "P", "dest", names.TOMB1_HALL_ENTRY)
end

-- The hall's first outgoing hatch enters the Tomb:2 ambush.
function markers.name_tomb1_hall_exit_1(api)
    mark(api, "Q", "name", names.TOMB1_HALL_EXIT_1)
end

-- The hall's second outgoing hatch lands in another Tomb:2 room.
function markers.name_tomb1_hall_exit_2(api)
    mark(api, "R", "name", names.TOMB1_HALL_EXIT_2)
end

-- Tomb:2's A glyph returns to the Tomb:1 hall entry.
function markers.name_tomb1_hall_entry(api)
    mark(api, "A", "name", names.TOMB1_HALL_ENTRY)
end

-- Tomb:2's C glyph receives the second hall exit.
function markers.dest_tomb1_hall_exit_2(api)
    mark(api, "C", "dest", names.TOMB1_HALL_EXIT_2)
end

-- Tomb:2's D glyph returns to Tomb:1's central area.
function markers.name_tomb2_exit(api)
    mark(api, "D", "name", names.TOMB2_EXIT)
end

-- The ambush's S glyph provides its own return to Tomb:1.
function markers.name_tomb2_exit_ambush(api)
    mark(api, "S", "name", names.TOMB2_EXIT)
end

-- Tomb:2's E glyph descends to Tomb:3's first landing.
function markers.name_tomb3_entry_1(api)
    mark(api, "E", "name", names.TOMB3_ENTRY_1)
end

-- Tomb:2's F glyph descends to Tomb:3's second landing.
function markers.name_tomb3_entry_2(api)
    mark(api, "F", "name", names.TOMB3_ENTRY_2)
end

-- Tomb:2's H glyph receives one return route from Tomb:3.
function markers.dest_tomb3_exit_1(api)
    mark(api, "H", "dest", names.TOMB3_EXIT_1)
end

-- Tomb:2's I glyph receives the other return route from Tomb:3.
function markers.dest_tomb3_exit_2(api)
    mark(api, "I", "dest", names.TOMB3_EXIT_2)
end

-- Tomb:2 ambush's R glyph receives the central Tomb:1 hatch.
function markers.dest_tomb2_entry(api)
    mark(api, "R", "dest", names.TOMB2_ENTRY)
end

-- The same ambush landing also receives the first hall hatch.
function markers.dest_tomb1_hall_exit_1(api)
    mark(api, "R", "dest", names.TOMB1_HALL_EXIT_1)
end

-- Tomb:3's D glyph receives the first downward hatch.
function markers.dest_tomb3_entry_1(api)
    mark(api, "D", "dest", names.TOMB3_ENTRY_1)
end

-- Tomb:3's E glyph receives the second downward hatch.
function markers.dest_tomb3_entry_2(api)
    mark(api, "E", "dest", names.TOMB3_ENTRY_2)
end

-- Tomb:3's F glyph returns to the first Tomb:2 landing.
function markers.name_tomb3_exit_1(api)
    mark(api, "F", "name", names.TOMB3_EXIT_1)
end

-- Tomb:3's H glyph returns to the second Tomb:2 landing.
function markers.name_tomb3_exit_2(api)
    mark(api, "H", "name", names.TOMB3_EXIT_2)
end

return markers
