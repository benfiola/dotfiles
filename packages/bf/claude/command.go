package claude

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/benfiola/dotfiles/packages/bf/tui"
	"github.com/urfave/cli/v3"
)

// Command browses, resumes, renames and deletes sessions.
func Command() *cli.Command {
	return &cli.Command{
		Name:  "claude",
		Usage: "browse, resume, rename and delete Claude Code sessions",
		Action: func(context.Context, *cli.Command) error {
			sessions, err := Discover()
			if err != nil {
				return err
			}
			_, _, err = tui.Run(picker(sessions))
			return err
		},
	}
}

func picker(sessions []Session) tui.Picker[Session] {
	return tui.Picker[Session]{
		Title: "Claude sessions",
		Items: sessions,
		Empty: "No Claude Code sessions found.",
		Rows:  rows,
		Actions: []tui.Action[Session]{
			{Keys: []string{"enter"}, Help: "resume", Do: resume},
			{Keys: []string{"r"}, Help: "rename", Do: rename},
			{Keys: []string{"d", "delete"}, Help: "delete", Do: remove},
		},
	}
}

func rows(sessions []Session) [][]string {
	rows := make([][]string, len(sessions))
	for i, s := range sessions {
		rows[i] = []string{fmt.Sprintf("%s  %7s  %s", s.ModTime.Format("2006-01-02 15:04"), formatSize(s.Size), s.Title)}
	}
	return rows
}

func formatSize(n int64) string {
	size := float64(n)
	for _, unit := range []string{"B", "KB", "MB", "GB"} {
		if size < 1024 {
			return fmt.Sprintf("%.0f%s", size, unit)
		}
		size /= 1024
	}
	return fmt.Sprintf("%.1fTB", size)
}

func replace(h *tui.Handle[Session], s Session) {
	items := append([]Session(nil), h.Items()...)
	items[h.Index()] = s
	h.SetItems(items)
}

func resume(h *tui.Handle[Session], s Session) {
	cmd := exec.Command("claude", "--resume", s.ID)
	if info, err := os.Stat(s.Cwd); err == nil && info.IsDir() {
		cmd.Dir = s.Cwd
	}
	h.Exec(cmd, func(err error) {
		replace(h, Load(s.Path))
		if err != nil {
			h.Message("resume failed: " + err.Error())
		}
	})
}

func rename(h *tui.Handle[Session], s Session) {
	h.Input("rename: ", s.Title, func(text string) {
		title := strings.TrimSpace(text)
		if title == "" {
			h.Message("Cancelled.")
			return
		}
		if err := s.Rename(title); err != nil {
			h.Message("rename failed: " + err.Error())
			return
		}
		replace(h, Load(s.Path))
	})
}

func remove(h *tui.Handle[Session], s Session) {
	h.Confirm(fmt.Sprintf("delete %s?", s.Title), func() {
		if err := s.Delete(); err != nil {
			h.Message("delete failed: " + err.Error())
			return
		}
		items := h.Items()
		i := h.Index()
		h.SetItems(append(append([]Session(nil), items[:i]...), items[i+1:]...))
	})
}
