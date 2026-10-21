// Package tui provides the terminal screens shared by bf's commands.
//
// Screens render to stderr so a command's stdout stays free for its result.
package tui

import (
	"errors"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
)

// ErrCancelled is returned when the user backs out of a prompt.
var ErrCancelled = errors.New("cancelled")

// Action is a hotkey on a Picker.
type Action[T any] struct {
	// Keys are tea key names ("enter", "d", "delete"); the first is shown in the header.
	Keys []string
	Help string
	// Always runs the action when the list is empty, passing the zero item.
	Always bool
	Do     func(h *Handle[T], item T)
}

// Picker is a scrollable list of items with hotkey actions.
type Picker[T any] struct {
	Title   string
	Items   []T
	Empty   string
	Actions []Action[T]
	// Rows returns the display lines of every item; each item may span several lines.
	Rows func(items []T) [][]string
}

// Handle lets an action change the picker it belongs to.
type Handle[T any] struct {
	m *model[T]
}

// Items returns the current items.
func (h *Handle[T]) Items() []T { return h.m.items }

// Index returns the selected item's index.
func (h *Handle[T]) Index() int { return h.m.idx }

// SetItems replaces the items, keeping the selection in range.
func (h *Handle[T]) SetItems(items []T) { h.m.setItems(items) }

// Message shows a one-line status.
func (h *Handle[T]) Message(text string) { h.m.message = text }

// Confirm asks for a y/N answer and calls yes on y.
func (h *Handle[T]) Confirm(prompt string, yes func()) {
	h.m.mode = modeConfirm
	h.m.prompt = prompt
	h.m.onYes = yes
}

// Input edits one line of text and calls submit on enter; escape cancels.
func (h *Handle[T]) Input(prompt, initial string, submit func(text string)) {
	h.m.mode = modeInput
	h.m.input = newInput(prompt, initial)
	h.m.onSubmit = submit
	h.m.cmd = textinput.Blink
}

// Exec suspends the screen to run a process, then calls done.
func (h *Handle[T]) Exec(cmd *exec.Cmd, done func(err error)) {
	h.m.cmd = tea.ExecProcess(cmd, func(err error) tea.Msg {
		return callbackMsg{func() { done(err) }}
	})
}

// Done closes the picker with a result.
func (h *Handle[T]) Done(item T) {
	h.m.result = &item
	h.m.cmd = tea.Quit
}

// Quit closes the picker without a result.
func (h *Handle[T]) Quit() { h.m.cmd = tea.Quit }

// Run shows the picker; ok reports whether an action called Done.
func Run[T any](p Picker[T]) (result T, ok bool, err error) {
	m := &model[T]{picker: p}
	m.setItems(p.Items)
	if err := runProgram(m); err != nil {
		return result, false, err
	}
	if m.result == nil {
		return result, false, nil
	}
	return *m.result, true, nil
}

func runProgram(m tea.Model) error {
	_, err := tea.NewProgram(m, tea.WithOutput(os.Stderr), tea.WithAltScreen()).Run()
	return err
}

func newInput(prompt, initial string) textinput.Model {
	in := textinput.New()
	in.Prompt = prompt
	in.SetValue(initial)
	in.CursorEnd()
	in.Focus()
	return in
}

type mode int

const (
	modeList mode = iota
	modeConfirm
	modeInput
)

type callbackMsg struct{ fn func() }

type model[T any] struct {
	picker        Picker[T]
	items         []T
	rows          [][]string
	idx, top      int
	width, height int
	message       string

	mode     mode
	prompt   string
	onYes    func()
	onSubmit func(string)
	input    textinput.Model

	// cmd is set by Handle methods and returned from the current Update.
	cmd    tea.Cmd
	result *T
}

// Screens draw on stderr, so styles must follow its color support and not stdout's, which a
// shell function may have captured.
var renderer = lipgloss.NewRenderer(os.Stderr)

func init() {
	lipgloss.SetDefaultRenderer(renderer)
}

var (
	boldStyle     = renderer.NewStyle().Bold(true)
	selectedStyle = renderer.NewStyle().Reverse(true)
	warnStyle     = renderer.NewStyle().Bold(true).Foreground(lipgloss.Color("1"))
)

func (m *model[T]) setItems(items []T) {
	m.items = items
	m.rows = m.picker.Rows(items)
	m.idx = max(0, min(m.idx, len(items)-1))
	m.scroll()
}

func (m *model[T]) takeCmd() tea.Cmd {
	cmd := m.cmd
	m.cmd = nil
	return cmd
}

func (m *model[T]) listHeight() int {
	return max(1, m.height-4)
}

func (m *model[T]) rowsHeight(from, to int) int {
	total := 0
	for _, lines := range m.rows[from:to] {
		total += len(lines)
	}
	return total
}

func (m *model[T]) scroll() {
	if len(m.items) == 0 {
		m.top = 0
		return
	}
	m.top = min(m.top, m.idx)
	for m.top < m.idx && m.rowsHeight(m.top, m.idx+1) > m.listHeight() {
		m.top++
	}
}

func (m *model[T]) move(delta int) {
	m.idx = max(0, min(m.idx+delta, len(m.items)-1))
	m.scroll()
}

func (m *model[T]) page() int {
	if len(m.rows) == 0 {
		return 1
	}
	return max(1, m.listHeight()/max(1, len(m.rows[m.top])))
}

func (m *model[T]) Init() tea.Cmd { return nil }

func (m *model[T]) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.scroll()
	case callbackMsg:
		msg.fn()
		return m, m.takeCmd()
	case tea.KeyMsg:
		switch m.mode {
		case modeConfirm:
			return m.updateConfirm(msg)
		case modeInput:
			return m.updateInput(msg)
		}
		return m.updateList(msg)
	}
	return m, nil
}

func (m *model[T]) updateConfirm(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	m.mode = modeList
	if msg.String() != "y" {
		m.message = "Cancelled."
		return m, nil
	}
	m.onYes()
	return m, m.takeCmd()
}

func (m *model[T]) updateInput(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter":
		m.mode = modeList
		m.onSubmit(m.input.Value())
		return m, m.takeCmd()
	case "esc", "ctrl+c":
		m.mode = modeList
		m.message = "Cancelled."
		return m, nil
	}
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m *model[T]) updateList(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	m.message = ""
	key := msg.String()
	for _, action := range m.picker.Actions {
		if !contains(action.Keys, key) || (len(m.items) == 0 && !action.Always) {
			continue
		}
		var item T
		if len(m.items) > 0 {
			item = m.items[m.idx]
		}
		action.Do(&Handle[T]{m}, item)
		return m, m.takeCmd()
	}

	switch key {
	case "q", "esc", "ctrl+c":
		return m, tea.Quit
	case "up", "k":
		m.move(-1)
	case "down", "j":
		m.move(1)
	case "pgup":
		m.move(-m.page())
	case "pgdown":
		m.move(m.page())
	case "home", "g":
		m.move(-len(m.items))
	case "end", "G":
		m.move(len(m.items))
	}
	return m, nil
}

func (m *model[T]) View() string {
	width, height := m.width, m.height
	if width == 0 || height == 0 {
		width, height = 80, 24
	}

	help := []string{}
	for _, action := range m.picker.Actions {
		help = append(help, action.Keys[0]+"="+action.Help)
	}
	help = append(help, "q=quit")
	header := " " + m.picker.Title + "   (" + strings.Join(help, "  ") + ")"
	rule := strings.Repeat("─", width)

	lines := []string{boldStyle.Render(ansi.Truncate(header, width, "")), rule}
	lines = append(lines, m.listLines(width, max(1, height-4))...)
	lines = append(lines, rule, m.status(width))
	return strings.Join(lines, "\n")
}

func (m *model[T]) listLines(width, height int) []string {
	lines := []string{}
	if len(m.items) == 0 {
		lines = append(lines, m.picker.Empty)
	}
	for i := m.top; i < len(m.items); i++ {
		if len(lines)+len(m.rows[i]) > height {
			break
		}
		for _, line := range m.rows[i] {
			line = ansi.Truncate(line, width, "")
			if i == m.idx {
				line = selectedStyle.Render(line + strings.Repeat(" ", max(0, width-ansi.StringWidth(line))))
			}
			lines = append(lines, line)
		}
	}
	for len(lines) < height {
		lines = append(lines, "")
	}
	return lines
}

func (m *model[T]) status(width int) string {
	switch m.mode {
	case modeConfirm:
		return warnStyle.Render(ansi.Truncate(m.prompt+" [y/N]", width, ""))
	case modeInput:
		return m.input.View()
	}
	return ansi.Truncate(m.message, width, "")
}

func contains(keys []string, key string) bool {
	for _, k := range keys {
		if k == key {
			return true
		}
	}
	return false
}
