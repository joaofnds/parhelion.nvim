"""sample module"""
from dataclasses import dataclass, field
import re as regex

PATTERN = regex.compile(r"^\d+$")

@dataclass
class Item:
    name: str = "x"
    tags: list[str] = field(default_factory=list)

    def label(self, *args, upper: bool = False, **kwargs) -> str:
        # comment
        value = f"{self.name}:{len(self.tags)!r}"
        return value.upper() if upper else value

async def main() -> None:
    try:
        for i, item in enumerate([Item(), None]):
            assert item is not None, "missing"
            print(i, item.label(upper=True), 0x10, 1.5, True)
    except ValueError as err:
        raise RuntimeError("bad") from err
    finally:
        pass
