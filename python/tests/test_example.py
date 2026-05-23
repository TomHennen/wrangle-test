"""Unit tests for the wrangle-test Python fixture.

wrangle's Python build runs this suite via ``pytest`` before it packages
the wheel/sdist — see build/actions/python/run_tests.sh in wrangle. A
failing test here fails the build, which is the point: it proves the
test step is actually wired up and executed.
"""

import pytest

from wrangle_test_fixture import add, hello, slugify


def test_hello():
    assert hello() == "wrangle-test-fixture"


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
