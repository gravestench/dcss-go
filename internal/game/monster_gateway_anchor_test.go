package game

import (
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
)

// A monster portal is distinct from the player's summon: its head owns a
// timer and a movable anchor. Save both coordinates after a head has appeared
// so restore cannot silently reconnect its chain to the old portal cell.
func TestMonsterGatewayDriftingAnchorRestores(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-gateway")
	movePlayerToOpenSummoningRoom(t, g)

	// The generated Dungeon corridor may be too narrow for the source's
	// clear eight-neighbor ring. Shape one small test room with the real grid
	// service, then let normal monster planning select its gateway cell.
	playerPosition, _ := g.stores.Positions.Get(g.player)
	level := g.levels[playerPosition.LevelID]

	for y := playerPosition.Y - 1; y <= playerPosition.Y+1; y++ {
		for x := playerPosition.X + 1; x <= playerPosition.X+5; x++ {
			if err := level.SetCell(x, y, terrain.Floor); err != nil {
				t.Fatal(err)
			}
		}
	}

	if err := level.MoveActor(caster,
		playerPosition.X+2, playerPosition.Y); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	energy, _ := g.stores.MonsterEnergy.Get(caster)
	energy.Points = 80

	events, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	markers := g.scripts.Components()["magic.summon_gateway"]

	if len(markers.Entities()) != 1 {
		t.Fatalf("monster gateway markers = %d, intent = %d, events = %+v",
			len(markers.Entities()), g.turn.ResolvedIntent, events)
	}

	originalMarker := markers.Entities()[0]
	marker, _ := markers.Get(originalMarker)

	if err := marker.Set("expires_aut", int64(g.currentAut)); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	portals := g.scripts.Components()["combat.portal_tentacle"]

	if len(portals.Entities()) != 1 {
		t.Fatalf("monster portal heads = %d", len(portals.Entities()))
	}

	head := portals.Entities()[0]
	portal, _ := portals.Get(head)
	xValue, _ := portal.Get("anchor_x")
	yValue, _ := portal.Get("anchor_y")
	wantX := xValue.(int64) + 1
	wantY := yValue.(int64)

	if err := portal.Set("anchor_x", wantX); err != nil {
		t.Fatal(err)
	}

	if err := portal.Set("anchor_y", wantY); err != nil {
		t.Fatal(err)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	saved, found := loaded.scripts.Components()["combat.portal_tentacle"].Get(head)

	if !found {
		t.Fatal("monster portal head lost on restore")
	}

	gotX, _ := saved.Get("anchor_x")
	gotY, _ := saved.Get("anchor_y")

	if gotX != wantX || gotY != wantY {
		t.Fatalf("restored anchor = (%v,%v), want (%d,%d)",
			gotX, gotY, wantX, wantY)
	}

	// DCSS removes the gateway marker when the head leaves its cell. The
	// head and connector must remain independently saveable afterward.
	if err := level.MoveActor(head,
		playerPosition.X+3, playerPosition.Y+1); err != nil {
		t.Fatal(err)
	}

	// A segment can briefly cross the old portal cell. Source keeps the
	// marker while any monster occupies it, then drops it on a later tick.
	for attempt := 0; attempt < 3; attempt++ {
		if _, found := markers.Get(originalMarker); !found {
			break
		}

		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if _, found := markers.Get(originalMarker); found {
		t.Fatal("vacated gateway marker still occupies the global slot")
	}

	if got := len(portals.Entities()); got != 1 {
		t.Fatalf("living portal heads = %d, want 1", got)
	}

	reloaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer reloaded.Close()

	if got := len(reloaded.scripts.Components()["combat.portal_tentacle"].Entities()); got != 1 {
		t.Fatalf("restored marker-free portal heads = %d, want 1", got)
	}
}
