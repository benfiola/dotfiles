package main

import (
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"sort"
	"strings"
	"time"

	"fyne.io/systray"
)

const confDir = "/etc/wireguard"
const pollInterval = 3 * time.Second

//go:embed icon.png
var icon []byte

type tunnel struct {
	name   string
	item   *systray.MenuItem
	active bool
	stop   chan struct{}
}

func main() {
	systray.Run(onReady, func() {})
}

func onReady() {
	systray.SetIcon(icon)
	systray.SetTooltip("WireGuard")
	systray.AddSeparator()

	quit := systray.AddMenuItem("Quit", "Quit")
	go func() {
		<-quit.ClickedCh
		systray.Quit()
	}()

	go func() {
		tunnels := map[string]*tunnel{}
		for {
			syncTunnels(tunnels)
			time.Sleep(pollInterval)
		}
	}()
}

func syncTunnels(tunnels map[string]*tunnel) {
	names := confNames()

	for name, t := range tunnels {
		if !contains(names, name) {
			close(t.stop)
			if t.active {
				exec.Command("systemctl", "stop", unit(name)).Run()
			}
			t.item.Remove()
			delete(tunnels, name)
		}
	}

	for _, name := range names {
		if _, ok := tunnels[name]; ok {
			continue
		}
		t := &tunnel{
			name: name,
			item: systray.AddMenuItemCheckbox(name, name, false),
			stop: make(chan struct{}),
		}
		tunnels[name] = t
		go watchTunnel(t)
	}
}

func confNames() []string {
	entries, err := os.ReadDir(confDir)
	if err != nil {
		fmt.Fprintln(os.Stderr, "reading", confDir, err)
		return nil
	}

	var names []string
	for _, e := range entries {
		if name, ok := strings.CutSuffix(e.Name(), ".conf"); ok {
			names = append(names, name)
		}
	}
	sort.Strings(names)
	return names
}

func contains(names []string, name string) bool {
	for _, n := range names {
		if n == name {
			return true
		}
	}
	return false
}

func watchTunnel(t *tunnel) {
	refresh(t)
	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()
	for {
		select {
		case <-t.stop:
			return
		case <-t.item.ClickedCh:
			toggle(t)
			refresh(t)
		case <-ticker.C:
			refresh(t)
		}
	}
}

func toggle(t *tunnel) {
	action := "start"
	if t.active {
		action = "stop"
	}
	if out, err := exec.Command("systemctl", action, unit(t.name)).CombinedOutput(); err != nil {
		fmt.Fprintf(os.Stderr, "systemctl %s %s: %v: %s\n", action, unit(t.name), err, out)
	}
}

func refresh(t *tunnel) {
	t.active = exec.Command("systemctl", "is-active", "--quiet", unit(t.name)).Run() == nil
	if t.active {
		t.item.Check()
	} else {
		t.item.Uncheck()
	}
}

func unit(name string) string {
	return "wg-quick@" + name + ".service"
}
