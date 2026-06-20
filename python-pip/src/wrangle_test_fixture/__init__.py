"""Disposable test fixture for wrangle integration tests.

The functions here exist purely so the package has real behavior for
the unit tests in ``tests/`` to exercise — wrangle's Python build
(``build_and_publish_python.yml``) runs ``pytest`` before packaging.
"""

__version__ = "0.0.1"


def hello() -> str:
    """Return the fixture's package name."""
    return "wrangle-test-fixture"


def add(*values: int) -> int:
    """Return the sum of ``values``.

    Raises ``TypeError`` if any value is not an ``int`` (``bool`` is
    rejected too, since ``isinstance(True, int)`` is otherwise true).
    """
    for value in values:
        if not isinstance(value, int) or isinstance(value, bool):
            raise TypeError(f"add() expects int values, got {value!r}")
    return sum(values)


def slugify(text: str) -> str:
    """Return ``text`` as a lowercase, single-hyphen-joined slug.

    Raises ``ValueError`` when ``text`` has no word characters.
    """
    words = text.lower().split()
    if not words:
        raise ValueError("slugify() requires non-empty text")
    return "-".join(words)
