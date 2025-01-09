import json
from typing import Any, List

from prodict import Prodict, DICT_RESERVED_KEYS


class DZConfig(Prodict):
    SETTINGS_FILE = 'dz_config.json'

    NAMESPACES = [
        "globals",
        "networking",
    ]
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DZConfig, cls).__new__(cls)
            cls._instance._initialized = False

        # Create config file if it doesn't exist
        try:
            with open(DZConfig.SETTINGS_FILE, "r") as f:
                pass
        except FileNotFoundError:
            with open(DZConfig.SETTINGS_FILE, "w") as f:
                f.write("{}")

        return cls._instance

    def __init__(self):
        super().__init__(**json.load(open(DZConfig.SETTINGS_FILE, "r")))

        if self._initialized:
            return

        self._initialized = True

        for ns in DZConfig.NAMESPACES:
            if not hasattr(self, ns):
                setattr(self, ns, {})
        self.save()

    def save(self):
        with open(DZConfig.SETTINGS_FILE, "w") as f:
            f.write(self.as_json())

    def as_json(self) -> str:
        return json.dumps(self.to_dict(exclude_none=True, is_recursive=True), indent=4)


