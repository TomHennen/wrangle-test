from wrangle_test_fixture import hello


def test_hello():
    assert hello() == "wrangle-test-fixture"
