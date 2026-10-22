package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Install one source-style permanent entrance in the generated scenario.
// The focused test uses real command, ECS, staging, shop, and save paths;
// source catalog tests separately check every authored entry map.
func placeBazaarPortalForTest(t *testing.T, g *Game, timed bool) point {
	t.Helper()

	site := placePortalForTest(t, g, terrain.EnterBazaar)
	level := g.levels[1]

	identity := `lua:one_way_stair { floor = "stone_arch" }`
	low := int64(0)
	high := int64(0)
	expires := int64(0)

	if timed {
		identity = `lua:timed_marker { low = 1, high = 1, single_timed = true, floor = "stone_arch" }`
		low = 1
		high = 1
		expires = int64(g.currentAut) + 10
	}

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: "bzr_entry_safe",
		Identity: identity,
		X:        site.x,
		Y:        site.y,
	}); err != nil {
		t.Fatal(err)
	}

	ids := append(level.VaultIDs(), "bzr_entry_safe")

	if err := level.SetVaultIDs(ids); err != nil {
		t.Fatal(err)
	}

	marker, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.bazaar_portal"]

	if _, err := store.Set(marker, map[string]any{
		"level_id":     int64(1),
		"x":            int64(site.x),
		"y":            int64(site.y),
		"vault_id":     "bzr_entry_safe",
		"record_index": int64(len(level.vaultRecords)),
		"low":          low,
		"high":         high,
		"expires_aut":  expires,
		"created_aut":  int64(g.currentAut),
		"timed":        timed,
		"spent":        false,
	}); err != nil {
		t.Fatal(err)
	}

	return site
}

// Staging can successfully populate a market and then reject the travel
// plan. The generic portal transaction must remove that market, restore its
// shop stock and RNG state, and leave the outside marker unchanged.
func TestBazaarRejectedStagedMapRollsBack(t *testing.T) {
	g := newGeneratedTestGame(t, 81425)
	placeBazaarPortalForTest(t, g, false)

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("Bazaar visitor has no position")
	}

	source := map[string]any{
		"level_id": int64(position.LevelID),
		"x":        int64(position.X),
		"y":        int64(position.Y),
	}

	generation := map[string]any{
		"species_id":  "SP_HUMAN",
		"player_name": "Tester",
	}

	plan := map[string]any{
		"operation":          "enter",
		"commit_policy":      "world.bazaar.commit_travel",
		"source":             source,
		"generate_policy":    "world.generate_bazaar_level",
		"generation_input":   generation,
		"expected_branch_id": "BRANCH_BAZAAR",
		"expected_level_id":  int64(999999),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), "another floor identity") {
		t.Fatalf("rejected Bazaar map returned %v", err)
	}

	afterState := g.Snapshot()

	// The ECS never reuses a destroyed entity ID. Rejected stage entities
	// may advance that cursor, while all playable and saved facts revert.
	afterState.EntityCursor = beforeState.EntityCursor

	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatalf("rejected Bazaar map changed saved state beyond the entity cursor: before %d bytes, after %d bytes",
			len(before), len(after))
	}
}

// Entering materializes an authored market and its shops. The one-way
// return must land at the exact outside arch and retire that market stock.
func TestBazaarEntryShopAndOneWayExit(t *testing.T) {
	g := newGeneratedTestGame(t, 81421)
	origin := placeBazaarPortalForTest(t, g, false)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	market := g.levels[position.LevelID]

	if market == nil ||
		market.BranchID != "BRANCH_BAZAAR" ||
		market.VaultID() == "" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatalf("Bazaar entry lost map or spent arch: %+v", position)
	}

	shops := g.scripts.Components()["world.shop"].Entities()

	if len(shops) == 0 {
		t.Fatal("Bazaar materialized no shops")
	}

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("active Bazaar save could not restore: %v", err)
	}

	shop, found := g.scripts.Components()["world.shop"].Get(shops[0])

	if !found {
		t.Fatal("Bazaar shop has no saved component")
	}

	fields, err := shop.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	x := int(fields["x"].(int64))
	y := int(fields["y"].(int64))

	if err := market.MoveActor(g.player, x, y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.wallet"].Set(
		g.player,
		map[string]any{
			"gold":      int64(100000),
			"purchases": int64(0),
		},
	); err != nil {
		t.Fatal(err)
	}

	view, err := g.ShopAtPlayer("type")

	if err != nil {
		t.Fatal(err)
	}

	if !view.Available || len(view.Items) == 0 {
		t.Fatalf("Bazaar shop has no purchasable stock: %+v", view)
	}

	first := view.Items[0]
	purchase, err := g.BuyShop(view.ID, []uint64{first.ID})

	if err != nil {
		t.Fatal(err)
	}

	if purchase.Spent != first.Price {
		t.Fatalf("Bazaar purchase spent %d, quoted %d",
			purchase.Spent, first.Price)
	}

	var exit point
	found = false

	for y, row := range market.Cells() {
		for x, feature := range row {
			if feature == terrain.ExitBazaar {
				exit = point{
					x: x,
					y: y,
				}

				found = true
				break
			}
		}

		if found {
			break
		}
	}

	if !found {
		t.Fatal("Bazaar map has no live exit")
	}

	if err := market.MoveActor(g.player, exit.x, exit.y); err != nil {
		t.Fatal(err)
	}

	marketID := market.ID

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ = g.stores.Positions.Get(g.player)

	if position.LevelID != 1 ||
		position.X != origin.x ||
		position.Y != origin.y ||
		g.levels[marketID] != nil {
		t.Fatalf("Bazaar did not return and retire: %+v", position)
	}

	if len(g.scripts.Components()["world.shop"].Entities()) != 0 {
		t.Fatal("retired Bazaar left shop stock in the ECS world")
	}
}

// A one-turn fixture exercises the same saved countdown path as the source
// depth-derived bounds without waiting hundreds of turns in a game test.
func TestBazaarTimedGateExpiresOnOutsideFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 81422)
	origin := placeBazaarPortalForTest(t, g, true)

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatal("timed Bazaar gate survived its deadline")
	}

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("expired Bazaar gate could not restore: %v", err)
	}

	if result, err := g.Step(Command{Kind: CommandDownstairs}); err != nil ||
		result.Spent != 0 {
		t.Fatalf("spent Bazaar gate allowed travel: %+v, %v", result, err)
	}
}

// Global aut keeps running after the player leaves the entrance floor.
// Expiring the inactive grid prevents a later save from retaining a live
// arch whose saved deadline has already passed.
func TestBazaarTimedGateExpiresWhileAway(t *testing.T) {
	g := newGeneratedTestGame(t, 81426)
	origin := placeBazaarPortalForTest(t, g, true)

	descendGeneratedTo(t, g, 2)

	if g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatal("inactive timed Bazaar gate survived its deadline")
	}

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("away expired Bazaar gate could not restore: %v", err)
	}
}

// A stair command prepared before the deadline keeps its accepted travel.
// The timer system runs inside that action and must not close the arch
// before the staged Bazaar commits its one-way transition.
func TestBazaarTimedGateAllowsTravelAtDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 81424)
	origin := placeBazaarPortalForTest(t, g, true)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found ||
		g.levels[position.LevelID].BranchID != "BRANCH_BAZAAR" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatalf("timed entry lost its accepted Bazaar travel: %+v", position)
	}
}

// The active market, return pointer, and countdown are reciprocal saved
// facts. Changing one field without changing its authored source is invalid.
func TestBazaarRestoreRejectsForgedState(t *testing.T) {
	g := newGeneratedTestGame(t, 81423)
	placeBazaarPortalForTest(t, g, false)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	wrongReturn := g.Snapshot()

	for index := range wrongReturn.Entities {
		for part := range wrongReturn.Entities[index].Dynamic {
			component := &wrongReturn.Entities[index].Dynamic[part]

			if component.Schema == "character.bazaar_visit" {
				component.Values["origin_x"] = json.RawMessage("999")
			}
		}
	}

	if _, err := Restore(wrongReturn); err == nil ||
		!strings.Contains(err.Error(), "Bazaar") {
		t.Fatalf("forged Bazaar return was accepted: %v", err)
	}

	wrongMap := g.Snapshot()
	alternate := "bazaar_jpeg_ninerooms_1"

	for index := range wrongMap.Levels {
		if wrongMap.Levels[index].BranchID == "BRANCH_BAZAAR" {
			if wrongMap.Levels[index].VaultID == alternate {
				alternate = "bazaar_jpeg_ninerooms_2"
			}

			wrongMap.Levels[index].VaultID = alternate
			wrongMap.Levels[index].VaultIDs = append(
				wrongMap.Levels[index].VaultIDs, alternate)
		}
	}

	encodedID, err := json.Marshal(alternate)

	if err != nil {
		t.Fatal(err)
	}

	for index := range wrongMap.Entities {
		for part := range wrongMap.Entities[index].Dynamic {
			component := &wrongMap.Entities[index].Dynamic[part]

			if component.Schema == "character.bazaar_visit" {
				component.Values["vault_id"] = encodedID
			}
		}
	}

	if _, err := Restore(wrongMap); err == nil ||
		!strings.Contains(err.Error(), "saved Bazaar has invalid layout") {
		t.Fatalf("forged Bazaar map was accepted: %v", err)
	}

	wrongTimer := g.Snapshot()

	for index := range wrongTimer.Entities {
		for part := range wrongTimer.Entities[index].Dynamic {
			component := &wrongTimer.Entities[index].Dynamic[part]

			if component.Schema == "world.bazaar_portal" {
				component.Values["expires_aut"] = json.RawMessage("10")
			}
		}
	}

	if _, err := Restore(wrongTimer); err == nil ||
		!strings.Contains(err.Error(), "Bazaar") {
		t.Fatalf("forged Bazaar timer was accepted: %v", err)
	}
}
