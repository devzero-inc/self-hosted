import json
from json import JSONDecodeError

from dotmap import DotMap


class DZDotMap(DotMap):
    def save(self):
        return DZConfig().save()

    def as_json(self):
        return DZConfig().as_json()

    def __delattr__(self, key):
        try:
            return self._map.__delitem__(key)
        except KeyError:
            return None



class DZConfig:
    SETTINGS_FILE = 'dz_config.json'

    NAMESPACES = [
        "globals",
        "control_plane",
        "data_planes",
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
        if self._initialized:
            return

        try:
            json_data = json.load(open(DZConfig.SETTINGS_FILE, "r"))
        except JSONDecodeError:
            json_data = {}

        self._data = DZDotMap(json_data)

        self._initialized = True

        # Forces namespace creation even when empty
        for ns in DZConfig.NAMESPACES:
            getattr(self._data, ns)
        self.save()

    @property
    def data(self):
        return self._data

    def save(self):
        with open(DZConfig.SETTINGS_FILE, "w") as f:
            f.write(self.as_json())

    def as_json(self) -> str:
        data = self.data.toDict()
        return json.dumps(data, indent=4)
