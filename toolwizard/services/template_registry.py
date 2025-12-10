# -*- coding: utf-8 -*-
import logging
from pathlib import Path

logger = logging.getLogger(__name__)


class TemplateRegistry:

    def __init__(self) -> None:
        pass

    def register(self, name: str, path: Path) -> None:
        pass

    def get(self, name: str) -> Path:
        pass

    def list_all(self) -> list[str]:
        pass
