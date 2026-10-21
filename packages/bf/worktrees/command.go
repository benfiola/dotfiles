package worktrees

import (
	"context"
	"errors"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/benfiola/dotfiles/packages/bf/tui"
	"github.com/urfave/cli/v3"
)

// Command is an interactive worktree manager. It prints the chosen or created worktree's
// path on stdout, so a shell function can cd to it.
func Command(opts Options) *cli.Command {
	return &cli.Command{
		Name:  "worktrees",
		Usage: "interactively manages git worktrees",
		Action: func(context.Context, *cli.Command) error {
			return opts.run()
		},
	}
}

func (o Options) run() error {
	o.prune()

	createNew := false
	chosen, ok, err := tui.Run(tui.Picker[Worktree]{
		Title: "Worktrees",
		Items: o.listAll(),
		Empty: "No worktrees found.",
		Rows:  rows,
		Actions: []tui.Action[Worktree]{
			{Keys: []string{"enter"}, Help: "go", Do: func(h *tui.Handle[Worktree], w Worktree) { h.Done(w) }},
			{Keys: []string{"e"}, Help: "edit description", Do: o.editDescription},
			{Keys: []string{"d"}, Help: "delete", Do: o.remove},
			{Keys: []string{"n"}, Help: "new", Always: true, Do: func(h *tui.Handle[Worktree], _ Worktree) {
				createNew = true
				h.Quit()
			}},
		},
	})
	if err != nil {
		return err
	}

	switch {
	case ok:
		fmt.Println(chosen.Path)
	case createNew:
		w, err := o.prompt()
		if err == nil {
			var path string
			if path, err = o.create(w); err == nil {
				fmt.Println(path)
			}
		}
		if errors.Is(err, tui.ErrCancelled) {
			return nil
		}
		return err
	}
	return nil
}

func rows(worktrees []Worktree) [][]string {
	repoWidth, branchWidth := 0, 0
	for _, w := range worktrees {
		repoWidth = max(repoWidth, len(filepath.Base(w.Repo)))
		branchWidth = max(branchWidth, len(w.Branch))
	}
	rows := make([][]string, len(worktrees))
	for i, w := range worktrees {
		rows[i] = []string{fmt.Sprintf("%-*s  %-*s  %s", repoWidth, filepath.Base(w.Repo), branchWidth, w.Branch, w.Description)}
	}
	return rows
}

func (o Options) reload(h *tui.Handle[Worktree]) {
	h.SetItems(o.listAll())
}

func (o Options) editDescription(h *tui.Handle[Worktree], w Worktree) {
	if w.Branch == detached {
		h.Message("cannot describe a detached worktree")
		return
	}
	h.Input("description: ", w.Description, func(text string) {
		if err := setDescription(w.Repo, w.Branch, strings.TrimSpace(text)); err != nil {
			h.Message("edit failed: " + err.Error())
			return
		}
		o.reload(h)
	})
}

func (o Options) remove(h *tui.Handle[Worktree], w Worktree) {
	detail := ""
	if warning := deleteWarning(w); warning != "" {
		detail = " (" + warning + ")"
	}
	h.Confirm(fmt.Sprintf("delete %s%s?", filepath.Base(w.Path), detail), func() {
		if _, err := git(w.Repo, "worktree", "remove", "--force", w.Path); err != nil {
			h.Message("delete failed: " + err.Error())
		}
		o.reload(h)
	})
}
