// Command bf is a collection of personal command line tools.
package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"github.com/benfiola/dotfiles/packages/bf/claude"
	"github.com/benfiola/dotfiles/packages/bf/worktrees"
	"github.com/urfave/cli/v3"
)

func main() {
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}

	cmd := &cli.Command{
		Name:  "bf",
		Usage: "personal command line tools",
		Commands: []*cli.Command{
			claude.Command(),
			worktrees.Command(worktrees.Options{SourceDir: filepath.Join(home, "source")}),
		},
	}
	if err := cmd.Run(context.Background(), os.Args); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}
