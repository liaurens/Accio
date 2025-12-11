# -*- coding: utf-8 -*-
from pathlib import Path


class TemplateRegistry:

    def __init__(self) -> None:
        pass

    def register(self, name: str, path: Path) -> None:
        pass

    def get(self, name: str) -> Path:
        raise NotImplementedError

    def list_all(self) -> list[str]:
        raise NotImplementedError
