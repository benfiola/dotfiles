package tui

import (
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
)

// Choose shows a menu and returns the index of the chosen option.
func Choose(prompt string, options []string) (int, error) {
	type option struct {
		index int
		label string
	}
	items := make([]option, len(options))
	for i, label := range options {
		items[i] = option{i, label}
	}

	chosen, ok, err := Run(Picker[option]{
		Title: prompt,
		Items: items,
		Rows: func(items []option) [][]string {
			rows := make([][]string, len(items))
			for i, item := range items {
				rows[i] = []string{"  " + item.label}
			}
			return rows
		},
		Actions: []Action[option]{{
			Keys: []string{"enter"},
			Help: "select",
			Do:   func(h *Handle[option], item option) { h.Done(item) },
		}},
	})
	if err != nil {
		return 0, err
	}
	if !ok {
		return 0, ErrCancelled
	}
	return chosen.index, nil
}

// Ask prompts for one line of text; validate may reject it with an error shown to the user.
func Ask(prompt, initial string, validate func(text string) error) (string, error) {
	m := &askModel{input: newInput(prompt+": ", initial), validate: validate}
	if err := runProgram(m); err != nil {
		return "", err
	}
	if !m.done {
		return "", ErrCancelled
	}
	return m.input.Value(), nil
}

type askModel struct {
	input    textinput.Model
	validate func(string) error
	err      error
	done     bool
}

func (m *askModel) Init() tea.Cmd { return textinput.Blink }

func (m *askModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	if key, ok := msg.(tea.KeyMsg); ok {
		switch key.String() {
		case "enter":
			if m.validate != nil {
				if m.err = m.validate(m.input.Value()); m.err != nil {
					return m, nil
				}
			}
			m.done = true
			return m, tea.Quit
		case "esc", "ctrl+c":
			return m, tea.Quit
		}
	}
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m *askModel) View() string {
	lines := []string{m.input.View(), ""}
	if m.err != nil {
		lines = append(lines, warnStyle.Render(m.err.Error()))
	}
	lines = append(lines, "enter=confirm  esc=cancel")
	return strings.Join(lines, "\n")
}
