package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

func distortionHobgoblin(t *testing.T, firstSeed uint64) (*Game, akara.Entity) {
	t.Helper()

	for seed := firstSeed; seed < firstSeed+16; seed++ {
		g := newGeneratedTestGame(t, seed)

		for _, monster := range g.stores.AI.Entities() {
			actor, _ := g.stores.Actors.Get(monster)

			if actor.KindID == "MONS_HOBGOBLIN" {
				return g, monster
			}
		}
	}

	t.Fatal("generated Dungeon has no hobgoblin")

	return nil, 0
}

func TestDistortionBanishmentCompletesStepAndReplaysEscape(t *testing.T) {
	g, monster := firstFloorHobgoblin(t)
	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_DISTORTION"

	health, _ := g.stores.Health.Get(g.player)
	var banished bool

	for attempt := 0; attempt < 300 && !banished; attempt++ {
		placePlayerBesideMonster(t, g, monster)

		health.Current = health.Max

		for _, entity := range g.stores.MonsterEnergy.Entities() {
			energy, _ := g.stores.MonsterEnergy.Get(entity)

			energy.Points = 0

			if entity == monster {
				energy.Points = 70
			}
		}

		result, err := g.Step(Command{Kind: CommandWait})

		if err != nil {
			t.Fatal(err)
		}

		position, _ := g.stores.Positions.Get(g.player)

		if position.LevelID == abyssStorageID {
			banished = true

			if result.View.LevelID != abyssStorageID ||
				g.levels[1].awaySinceAut == nil ||
				g.levels[abyssStorageID].awaySinceAut != nil {
				t.Fatal("Step did not activate the Abyss after banishment")
			}
		}
	}

	if !banished {
		t.Fatal("distortion never banished the player during Step")
	}

	health.Current = health.Max

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("banished turn changed across save and restore")
	}

	for _, run := range []*Game{g, loaded} {
		if err := run.levels[abyssStorageID].MoveActor(run.player, 40, 35); err != nil {
			t.Fatal(err)
		}

		// Banishment lands on ordinary floor. Install a real Abyss exit
		// to test the return path without relying on the old fixed stair.
		if err := run.levels[abyssStorageID].SetCell(40, 35,
			terrain.ExitAbyss); err != nil {
			t.Fatal(err)
		}

		result, err := run.Step(Command{Kind: CommandUpstairs})

		if err != nil {
			t.Fatal(err)
		}

		if result.View.LevelID != 1 ||
			run.scripts.Components()["world.banishment"].Has(run.player) {
			t.Fatal("Abyss escape did not return to Dungeon:1")
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("Abyss escape diverged after save and restore")
	}
}

func TestDistortionBlinkMovesPlayerAndOccupancy(t *testing.T) {
	g, monster := distortionHobgoblin(t, 2)
	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_DISTORTION"

	playerHealth, _ := g.stores.Health.Get(g.player)
	var warped bool

	for attempt := 0; attempt < 100; attempt++ {
		placePlayerBesideMonster(t, g, monster)

		playerHealth.Current = playerHealth.Max

		before, _ := g.stores.Positions.Get(g.player)
		originX, originY := before.X, before.Y
		events, err := g.runAction(monster, ecs.Intent{}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range events {
			warped = warped || strings.Contains(event.Text, "Space warps")

			if !strings.Contains(event.Text, "You blink away!") {
				continue
			}

			position, _ := g.stores.Positions.Get(g.player)
			occupant, found := g.levels[1].ActorAt(position.X, position.Y)

			if position.LevelID != 1 ||
				(position.X == originX && position.Y == originY) ||
				!found ||
				occupant != g.player ||
				!warped {
				t.Fatalf("distortion blink left position %+v, occupant %d", position, occupant)
			}

			return
		}

		position, _ := g.stores.Positions.Get(g.player)

		if position.LevelID == abyssStorageID {
			t.Fatal("banishment preceded the expected blink")
		}
	}

	t.Fatal("distortion never blinked the player")
}

func TestDistortionBanishesAndEscapesThroughSavedAbyss(t *testing.T) {
	g, monster := distortionHobgoblin(t, 1)
	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_DISTORTION"

	playerHealth, _ := g.stores.Health.Get(g.player)

	for attempt := 0; attempt < 200; attempt++ {
		placePlayerBesideMonster(t, g, monster)

		playerHealth.Current = playerHealth.Max

		if _, err := g.runAction(monster, ecs.Intent{}, 10, "monster"); err != nil {
			t.Fatal(err)
		}

		position, _ := g.stores.Positions.Get(g.player)

		if position.LevelID == abyssStorageID {
			if err := g.activateTransition(1, abyssStorageID, g.currentAut); err != nil {
				t.Fatal(err)
			}

			break
		}
	}

	position, _ := g.stores.Positions.Get(g.player)

	if position.LevelID != abyssStorageID {
		t.Fatal("distortion never banished the player")
	}

	playerHealth.Current = playerHealth.Max

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	position, _ = loaded.stores.Positions.Get(loaded.player)

	if position.LevelID != abyssStorageID {
		t.Fatalf("restored banished player on level %d", position.LevelID)
	}

	if err := loaded.levels[abyssStorageID].MoveActor(loaded.player, 40, 35); err != nil {
		t.Fatal(err)
	}

	if err := loaded.levels[abyssStorageID].SetCell(40, 35,
		terrain.ExitAbyss); err != nil {
		t.Fatal(err)
	}

	result, err := loaded.Step(Command{Kind: CommandUpstairs})

	if err != nil {
		t.Fatal(err)
	}

	if result.View.LevelID != 1 ||
		loaded.scripts.Components()["world.banishment"].Has(loaded.player) {
		t.Fatalf("Abyss escape left player on level %d", result.View.LevelID)
	}
}
