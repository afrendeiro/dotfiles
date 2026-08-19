import subprocess
from urllib.parse import unquote

from gi.repository import GObject, Nautilus

TERMINAL = "kitty"


class OpenTerminal(GObject.GObject, Nautilus.MenuProvider):
    def _open_terminal(self, path):
        subprocess.Popen(
            [TERMINAL, "-d", path],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def menu_activate_cb(self, menu, file):
        self._open_terminal(unquote(file.get_uri()[7:]))

    def menu_background_activate_cb(self, menu, current_folder):
        self._open_terminal(unquote(current_folder.get_uri()[7:]))

    def get_file_items(self, files):
        if len(files) != 1:
            return []
        file = files[0]
        if not file.is_directory() or file.get_uri_scheme() != "file":
            return []
        item = Nautilus.MenuItem(
            name="NautilusPython::openterminal_file_item",
            label="Open Terminal Here",
        )
        item.connect("activate", self.menu_activate_cb, file)
        return [item]

    def get_background_items(self, current_folder):
        if current_folder is None:
            return []
        item = Nautilus.MenuItem(
            name="NautilusPython::openterminal_background_item",
            label="Open Terminal Here",
        )
        item.connect("activate", self.menu_background_activate_cb, current_folder)
        return [item]
