package game

import (
	"strings"
	"testing"

	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

// Move a real Akara monster beside the prepared gate. Its current target
// and action energy satisfy the same source gates as an ordinary stair
// pursuer, so the portal path is the only variable in these tests.
func placePortalPursuer(t *testing.T, g *Game, site point) akara.Entity {
	t.Helper()
	worm := spawnWormForTest(t, g, 1)
	g.levels[1].initialActors++
	movePortalPursuer(t, g, worm, site)

	return worm
}

// Reposition the same pursuer for a later portal. This also exercises
// region replacement without inventing a second monster or copying state.
func movePortalPursuer(t *testing.T, g *Game, worm akara.Entity, site point) {
	t.Helper()
	position, found := g.stores.Positions.Get(worm)

	if !found {
		t.Fatal("pursuer has no position")
	}

	level := g.levels[position.LevelID]
	placed := false

	for dy := -1; dy <= 1 && !placed; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue
			}

			x := site.x + dx
			y := site.y + dy

			if !level.Walkable(x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if err := level.MoveActor(worm, x, y); err != nil {
				t.Fatal(err)
			}

			placed = true
			break
		}
	}

	if !placed {
		t.Fatal("portal has no adjacent cell for a pursuer")
	}

	ai, _ := g.stores.AI.Get(worm)
	ai.Behavior = "seek"
	ai.TargetX = site.x
	ai.TargetY = site.y

	energy, _ := g.stores.MonsterEnergy.Get(worm)
	energy.Points = 60
	health, _ := g.stores.Health.Get(worm)
	health.Max = 18
	health.Current = 18
}

// The Vestibule is a connected destination. A tagged pursuer crosses the
// real Hell portal as one ECS identity, retaining its carried weapon.
func TestHellPortalCarriesOrdinaryPursuer(t *testing.T) {
	g := newGeneratedTestGame(t, 8101)
	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max
	originalCurrent := health.Current
	health.Max = 10000
	health.Current = health.Max

	site := placePortalForTest(t, g, terrain.EnterHell)
	worm := placePortalPursuer(t, g, site)
	weapon := giveTestMonsterWeapon(t, g, worm)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	player, _ := g.stores.Positions.Get(g.player)
	follower, found := g.stores.Positions.Get(worm)

	if !found || follower.LevelID != player.LevelID ||
		g.scripts.Components()["world.stair_follower"].Has(worm) {
		t.Fatalf("pursuer did not complete Hell transit: %+v", follower)
	}

	resetHellTestHealth(g, originalMax, originalCurrent)

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	carrier, found := restored.stores.CarriedBy.Get(weapon)

	if !found || carrier.Holder != worm {
		t.Fatalf("portal follower lost carried weapon: %+v", carrier)
	}
}

// The Bailey is isolated. An ordinary monster may be tagged at its arch,
// but destination eligibility clears the mark and leaves it outside.
func TestBaileyPortalLeavesOrdinaryPursuerOutside(t *testing.T) {
	g := newGeneratedTestGame(t, 88142)
	site := placeBaileyPortalForTest(t, g)
	worm := placePortalPursuer(t, g, site)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(worm)

	if !found || position.LevelID != 1 ||
		g.scripts.Components()["world.stair_follower"].Has(worm) {
		t.Fatalf("ordinary monster entered Bailey: %+v", position)
	}
}

// Pan is an explicit follower exception in source. Its next portal retires
// the previous region, but a following actor and its gear remain live.
func TestPanTransitCarriesPursuerAcrossRegionReplacement(t *testing.T) {
	g := newGeneratedTestGame(t, 8102)
	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max
	originalCurrent := health.Current
	health.Max = 10000
	health.Current = health.Max

	site := placePortalForTest(t, g, terrain.EnterPandemonium)
	worm := placePortalPursuer(t, g, site)
	weapon := giveTestMonsterWeapon(t, g, worm)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	firstRegion := g.panState.ActiveLevelID
	position, found := g.stores.Positions.Get(worm)

	if !found || position.LevelID != firstRegion {
		t.Fatalf("pursuer did not enter Pan: %+v", position)
	}

	site = placePortalForTest(t, g, terrain.TransitPandemonium)
	movePortalPursuer(t, g, worm, site)

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, found = g.stores.Positions.Get(worm)

	if !found || position.LevelID != g.panState.ActiveLevelID ||
		g.levels[firstRegion] != nil ||
		g.scripts.Components()["world.stair_follower"].Has(worm) {
		t.Fatalf("pursuer did not survive Pan replacement: %+v", position)
	}

	resetHellTestHealth(g, originalMax, originalCurrent)
	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	carrier, found := restored.stores.CarriedBy.Get(weapon)

	if !found || carrier.Holder != worm {
		t.Fatalf("Pan follower lost its weapon: %+v", carrier)
	}
}

// A saved transit marker cannot claim a different branch for an active
// source floor just to bypass that floor's monster roster rules.
func TestRestoreRejectsForgedMonsterTransitBranch(t *testing.T) {
	g := newGeneratedTestGame(t, 8104)
	worm := spawnWormForTest(t, g, 1)
	g.levels[1].initialActors++

	_, err := g.scripts.Components()["world.monster_transit_origin"].Set(
		worm,
		map[string]any{
			"level_id":  int64(1),
			"branch_id": "BRANCH_PANDEMONIUM",
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if loaded != nil {
		defer loaded.Close()
	}

	if err == nil || !strings.Contains(err.Error(), "invalid transit origin") {
		t.Fatalf("forged transit origin was accepted: %v", err)
	}
}
