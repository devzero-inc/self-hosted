import json
from json import JSONDecodeError
from typing import Any, List

from prodict import Prodict, DICT_RESERVED_KEYS


class DZConfig(Prodict):
    SETTINGS_FILE = 'dz_config.json'

    NAMESPACES = [
        "globals",
        "control_plane",
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
        try:
            json_data = json.load(open(DZConfig.SETTINGS_FILE, "r"))
        except JSONDecodeError:
            json_data = {}

        super().__init__(**json_data)

        if self._initialized:
            return

        self._initialized = True

        for ns in DZConfig.NAMESPACES:
            if not hasattr(self, ns):
                setattr(self, ns, {})
        self.save()

    def __getattr__(self, item):
        try:
            return self[item]
        except KeyError:
            self[item] = Prodict()
            return self[item]


    def save(self):
        with open(DZConfig.SETTINGS_FILE, "w") as f:
            f.write(self.as_json())

    def as_json(self) -> str:
        data = self.to_dict(exclude_none=True, is_recursive=True)
        # Remove the _initialized attribute
        del data["_initialized"]
        return json.dumps(data, indent=4)


