package terminal

import (
	"strings"
	"testing"

	"dcrawl-go/internal/save"
)

func TestTakeOffAndWearArmourMenusKeepInventoryLetters(t *testing.T) {
	m := playingModel(t)
	shieldLetter := inventoryLetter(t, m, "ARM_BUCKLER")
	start := m.game.View().CurrentAut

	m.handleKey("T")

	if m.screen != ScreenTakeOff ||
		!strings.Contains(plainApp(m), "Take off which item?") {
		t.Fatal("takeoff menu missing")
	}

	m.handleKey(shieldLetter)

	if m.screen != ScreenPlay || m.game.View().EquipmentDelay == nil {
		t.Fatal("takeoff did not start a scheduled delay")
	}

	for turn := 0; turn < 4; turn++ {
		_, command := m.Update(equipmentTick{id: m.equipmentTickID})

		if turn < 3 && command == nil {
			t.Fatal("takeoff stopped before its final turn")
		}
	}

	if m.game.View().EquipmentDelay != nil ||
		m.game.View().CurrentAut != start+50 {
		t.Fatal("takeoff did not finish after five turns")
	}

	m.handleKey("W")

	if m.screen != ScreenWear ||
		!strings.Contains(plainApp(m), "Wear which item?") {
		t.Fatal("wear menu missing")
	}

	m.handleKey(shieldLetter)

	for turn := 0; turn < 4; turn++ {
		m.Update(equipmentTick{id: m.equipmentTickID})
	}

	if m.game.View().EquipmentDelay != nil ||
		m.game.View().CurrentAut != start+100 {
		t.Fatal("wear did not finish after five turns")
	}
}

func TestEscapeInterruptsEquipmentDelayWithoutSpendingTime(t *testing.T) {
	m := playingModel(t)
	shieldLetter := inventoryLetter(t, m, "ARM_BUCKLER")

	m.handleKey("T")
	m.handleKey(shieldLetter)
	before := m.game.View().CurrentAut
	m.handleKey("esc")

	if m.game.View().EquipmentDelay != nil ||
		m.game.View().CurrentAut != before {
		t.Fatal("escape did not cancel the delay without time")
	}

	_, command := m.Update(equipmentTick{id: m.equipmentTickID - 1})

	if command != nil || m.game.View().CurrentAut != before {
		t.Fatal("stale equipment tick resumed a cancelled action")
	}
}

func TestSaveControlsWorkDuringEquipmentDelay(t *testing.T) {
	m := playingModel(t)
	shieldLetter := inventoryLetter(t, m, "ARM_BUCKLER")

	m.handleKey("T")
	m.handleKey(shieldLetter)
	before := m.game.View().CurrentAut
	m.handleKey("S")

	if m.screen != ScreenConfirm {
		t.Fatal("save confirmation is unavailable during delay")
	}

	command := m.handleKey("n")

	if m.screen != ScreenPlay || command == nil ||
		m.game.View().CurrentAut != before {
		t.Fatal("cancelled save failed to resume equipment delay")
	}

	if command := m.handleKey("ctrl+s"); command == nil {
		t.Fatal("immediate save did not request exit")
	}

	snapshot, err := save.Read(m.savePath)

	if err != nil {
		t.Fatal(err)
	}

	for _, entity := range snapshot.Entities {
		if entity.ID == snapshot.PlayerID && entity.Equipment != nil {
			return
		}
	}

	t.Fatal("mid-delay save omitted the player equipment state")
}
