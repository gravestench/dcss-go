package game

import "crawl/internal/terrain"

func fixtureFeature(glyph byte) terrain.ID {
	switch glyph {
	case '#':
		return terrain.RockWall

	case '.':
		return terrain.Floor

	case '+':
		return terrain.ClosedDoor

	case '\'':
		return terrain.OpenDoor

	case '<':
		return terrain.StairsUp

	case '>':
		return terrain.StairsDown

	default:
		return terrain.ID(string(glyph))
	}
}

func fixtureCells(rows []string) [][]terrain.ID {
	cells := make([][]terrain.ID, len(rows))

	for y, row := range rows {
		cells[y] = make([]terrain.ID, len(row))

		for x := range row {
			cells[y][x] = fixtureFeature(row[x])
		}
	}

	return cells
}

func fixtureGlyph(feature terrain.ID) rune {
	return terrain.Glyph(feature)
}

func fixtureRow(row []terrain.ID) string {
	glyphs := make([]rune, len(row))

	for x, feature := range row {
		glyphs[x] = terrain.Glyph(feature)
	}

	return string(glyphs)
}
