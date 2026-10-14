package terminal

import "dcrawl-go/internal/game"

// dungeonRenderer projects the read-only level view into the map pane.
type dungeonRenderer struct {
	canvas  *Canvas
	region  Region
	view    game.View
	centerX int
	centerY int
}

func drawDungeon(canvas *Canvas, region Region, view game.View) {
	if view.Width <= 0 {
		return
	}

	renderer := dungeonRenderer{
		canvas:  canvas,
		region:  region,
		view:    view,
		centerX: region.X + region.W/2,
		centerY: region.Y + region.H/2,
	}

	renderer.drawTerrain()
	renderer.drawEntities()
}

func (r dungeonRenderer) drawTerrain() {
	for index, cell := range r.view.Cells {
		if cell.State == game.Unknown {
			continue
		}

		x := index % r.view.Width
		y := index / r.view.Width
		screenX, screenY, visible := r.screenPoint(x, y)

		if !visible {
			continue
		}

		r.canvas.Put(screenX, screenY, cell.Glyph, terrainColor(cell), Black)
	}
}

func terrainColor(cell game.CellView) Color {
	if cell.State != game.Visible {
		return DarkGrey
	}

	if cell.Glyph == '<' || cell.Glyph == '>' {
		return Yellow
	}

	return LightGrey
}

func (r dungeonRenderer) drawEntities() {
	// Draw the player last, even when the view lists it before a floor item.
	for _, playerPass := range []bool{false, true} {
		for _, entity := range r.view.Entities {
			if (entity.Role == "player") != playerPass {
				continue
			}

			r.drawEntity(entity)
		}
	}
}

func (r dungeonRenderer) drawEntity(entity game.EntityView) {
	screenX, screenY, visible := r.screenPoint(entity.X, entity.Y)

	if !visible {
		return
	}

	r.canvas.Put(screenX, screenY, entity.Glyph, entityColor(entity), Black)
}

func entityColor(entity game.EntityView) Color {
	switch entity.Role {
	case "player":
		return White

	case "monster":
		return Brown

	case "item":
		switch entity.KindID {
		case "CORPSE_BODY":
			return Brown

		case "CORPSE_SKELETON":
			return LightGrey
		}

		return LightGreen
	}

	return LightGrey
}

func (r dungeonRenderer) screenPoint(x, y int) (int, int, bool) {
	screenX := r.centerX + x - r.view.PlayerX
	screenY := r.centerY + y - r.view.PlayerY
	inX := screenX >= r.region.X && screenX < r.region.X+r.region.W
	inY := screenY >= r.region.Y && screenY < r.region.Y+r.region.H

	return screenX, screenY, inX && inY
}
