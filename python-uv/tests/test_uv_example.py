"""Unit tests for the uv-managed wrangle-test Python fixture.

wrangle's Python build runs this suite via ``uv run pytest`` before it
packages the wheel/sdist. A failing test here fails the build — proof
that the test step is wired up and executed on the uv tooling path.
"""

import pytest

from wrangle_test_uv_fixture import add, hello, slugify


def test_hello():
    assert hello() == "wrangle-test-uv-fixture"


def test_add_sums_values():
    assert add(1, 2, 3) == 6
    assert add() == 0
    assert add(-4, 4) == 0


def test_add_rejects_non_int():
    with pytest.raises(TypeError):
        add(1, "2")
    with pytest.raises(TypeError):
        add(True)  # bool is not accepted even though it subclasses int


def test_slugify_normalizes_case_and_whitespace():
    assert slugify("Hello World") == "hello-world"
    assert slugify("  Wrangle   Test  ") == "wrangle-test"


def test_slugify_rejects_empty():
    with pytest.raises(ValueError):
        slugify("   ")
