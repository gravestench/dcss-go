package terminal

import (
	"fmt"
	"os"
	"time"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
)

type ScreenID uint8

type confirmation uint8

const (
	confirmNone confirmation = iota
	confirmSave
	confirmAbandon
)

const (
	ScreenStartup ScreenID = iota
	ScreenSpecies
	ScreenBackground
	ScreenWeapon
	ScreenName
	ScreenPlay
	ScreenInventory
	ScreenSkills
	ScreenHelp
	ScreenConfirm
	ScreenDeath
	ScreenQuaff
	ScreenStatChoice
	ScreenDrop
	ScreenWield
	ScreenWear
	ScreenTakeOff
)

type equipmentTick struct {
	id uint64
}

// AppModel owns terminal navigation; the Game owns every turn-changing state.
type AppModel struct {
	catalog      content.Catalog
	presentation content.PresentationArtifact
	seed         uint64
	savePath     string
	game         *game.Game

	screen       ScreenID
	previous     ScreenID
	weaponReturn ScreenID
	width        int
	height       int

	name             string
	speciesID        string
	jobID            string
	weaponID         string
	options          []character.WeaponOption
	focus            int
	skillFocusAction bool

	notice          string
	confirm         confirmation
	dropQuantity    string
	pendingDoor     game.CommandKind
	equipmentTickID uint64
}

func NewAppModel(catalog content.Catalog, seed uint64, savePath string) (*AppModel, error) {
	if err := catalog.Validate(); err != nil {
		return nil, err
	}

	if len(catalog.Presentation().SpeciesGroups) != 3 {
		return nil, fmt.Errorf("catalog lacks console presentation")
	}

	return &AppModel{
		catalog:      catalog,
		presentation: catalog.Presentation(),
		seed:         seed,
		savePath:     savePath,
		screen:       ScreenStartup,
		width:        79,
		height:       24,
	}, nil
}

func (m *AppModel) Init() tea.Cmd {
	if m.game != nil && m.game.View().EquipmentDelay != nil {
		return m.nextEquipmentTick()
	}

	return nil
}

func (m *AppModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case tea.KeyPressMsg:
		return m, m.handleKey(msg.String())

	case equipmentTick:
		if msg.id != m.equipmentTickID ||
			m.screen != ScreenPlay ||
			m.game == nil || m.game.View().EquipmentDelay == nil {
			return m, nil
		}

		return m, m.stepPlayCommand(game.Command{
			Kind: game.CommandContinueEquipment,
		})
	}

	return m, nil
}

func (m *AppModel) handleKey(key string) tea.Cmd {
	if _, valid := ComputeLayout(m.width, m.height); !valid {
		return nil
	}

	switch m.screen {
	case ScreenStartup:
		return m.handleStartupKey(key)

	case ScreenSpecies, ScreenBackground:
		m.handleCharacterChoiceKey(key)

	case ScreenWeapon:
		m.handleWeaponKey(key)

	case ScreenName:
		m.handleNameKey(key)

	case ScreenPlay:
		return m.handlePlayKey(key)

	case ScreenStatChoice:
		m.handleStatChoiceKey(key)

	case ScreenInventory:
		m.handleModalKey(key)

	case ScreenSkills:
		m.handleSkillsKey(key)

	case ScreenQuaff:
		return m.handleQuaffKey(key)

	case ScreenDrop:
		return m.handleDropKey(key)

	case ScreenWield:
		return m.handleWieldKey(key)

	case ScreenWear, ScreenTakeOff:
		return m.handleArmourKey(key)

	case ScreenConfirm:
		return m.handleConfirmKey(key)

	case ScreenDeath:
		if key == "esc" || key == "enter" {
			m.returnToStartup()
		}

	case ScreenHelp:
		if key == "esc" {
			m.screen = m.previous
			m.notice = ""
		} else {
			m.notice = "This help control is unavailable in the Go port."
		}
	}

	return nil
}

func (m *AppModel) renderCanvas() *Canvas {
	canvas := NewCanvas(m.width, m.height)
	layout, ok := ComputeLayout(m.width, m.height)

	if !ok {
		message := "Your terminal window is too small; please resize to at least 79,24"
		canvas.Write(0, 0, message, LightGrey, Black)

		return canvas
	}

	switch m.screen {
	case ScreenStartup:
		m.drawStartup(canvas)

	case ScreenSpecies, ScreenBackground:
		m.drawCharacterChoice(canvas)

	case ScreenWeapon:
		m.drawWeapon(canvas)

	case ScreenName:
		m.drawName(canvas)

	case ScreenPlay, ScreenStatChoice:
		if m.game != nil {
			DrawPlay(canvas, layout, m.game.View(), m.notice)
		}

		if m.screen == ScreenStatChoice && m.game != nil {
			canvas.Write(
				0, m.height-1,
				"Increase (S)trength, (I)ntelligence, or (D)exterity?",
				LightGrey, Black,
			)
		}

	case ScreenInventory, ScreenSkills, ScreenQuaff, ScreenDrop,
		ScreenWield, ScreenWear, ScreenTakeOff:
		m.drawGameMenu(canvas)

	case ScreenHelp:
		DrawHelp(canvas)
		m.drawModalNotice(canvas)

	case ScreenConfirm:
		m.drawConfirm(canvas)

	case ScreenDeath:
		canvas.Write(0, 0, "You die...", LightRed, Black)
		canvas.Write(0, 2, "Press Enter to return to startup.", LightGrey, Black)
		canvas.Write(0, 4, "Morgue and high scores are unavailable in the Go port.", Brown, Black)
	}

	return canvas
}

func (m *AppModel) drawGameMenu(canvas *Canvas) {
	if m.game != nil {
		view := m.game.View()

		switch m.screen {
		case ScreenInventory:
			DrawInventory(canvas, view)

		case ScreenSkills:
			DrawSkills(canvas, view, m.catalog, m.skillFocusAction)

		case ScreenQuaff:
			DrawQuaff(canvas, view)

		case ScreenDrop:
			DrawDrop(canvas, view, m.dropQuantity)

		case ScreenWield:
			DrawWield(canvas, view)

		case ScreenWear, ScreenTakeOff:
			DrawArmour(canvas, view, m.screen == ScreenTakeOff)
		}
	}

	m.drawModalNotice(canvas)
}

func (m *AppModel) nextEquipmentTick() tea.Cmd {
	m.equipmentTickID++
	id := m.equipmentTickID

	return tea.Tick(80*time.Millisecond, func(time.Time) tea.Msg {
		return equipmentTick{id: id}
	})
}

func (m *AppModel) View() tea.View {
	view := tea.NewView(m.renderCanvas().Styled())
	view.AltScreen = true

	return view
}

func (m *AppModel) Close() error {
	if m.game != nil {
		return m.game.Close()
	}

	return nil
}

func (m *AppModel) savedRunExists() bool {
	_, err := os.Stat(m.savePath)

	return err == nil
}

func (m *AppModel) loadSavedRun() {
	snapshot, err := save.Read(m.savePath)

	if err != nil {
		m.notice = fmt.Sprintf("Load failed: %v", err)

		return
	}

	restored, err := game.Restore(snapshot, m.catalog)

	if err != nil {
		m.notice = fmt.Sprintf("Load failed: %v", err)

		return
	}

	if m.game != nil {
		_ = m.game.Close()
	}

	m.game = restored
	m.screen = ScreenPlay

	if restored.View().PendingStatLevel != 0 {
		m.screen = ScreenStatChoice
	}

	m.notice = ""
}

func (m *AppModel) returnToStartup() {
	if m.game != nil {
		_ = m.game.Close()
	}

	m.game = nil

	m.screen = ScreenStartup
	m.previous = ScreenStartup
	m.weaponReturn = ScreenStartup

	m.name = ""

	m.speciesID = ""
	m.jobID = ""
	m.weaponID = ""

	m.options = nil

	m.focus = 0
	m.notice = ""

	m.confirm = confirmNone
	m.pendingDoor = 0
}
