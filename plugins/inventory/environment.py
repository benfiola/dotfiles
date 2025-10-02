import os
import sys

from ansible.plugins.inventory import BaseInventoryPlugin


class InventoryModule(BaseInventoryPlugin):
    NAME = "benfiola.dotfiles.environment"
    TYPE = "generator"

    def verify_file(self, path):
        return any(["LOCAL" in os.environ, "REMOTE_IP" in os.environ])

    def parse(self, inventory, loader, path, cache=True):
        super(InventoryModule, self).parse(inventory, loader, path, cache=cache)
        self.parse_from_environment()

    def parse_from_environment(self):
        host_vars = {}

        is_local = os.environ.get("LOCAL")
        remote_ip = os.environ.get("REMOTE_IP")
        if is_local:
            host = "localhost"
            host_vars["ansible_connection"] = "local"
            host_vars["ansible_python_interpreter"] = sys.executable
        elif remote_ip:
            host = remote_ip
        else:
            raise ValueError(f"host undefined")

        self.inventory.add_host(host)
        for key, value in host_vars.items():
            self.inventory.set_variable(host, key, value)
            self.inventory.set_variable(host, key, value)
