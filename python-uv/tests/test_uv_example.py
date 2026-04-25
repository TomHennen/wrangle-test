from wrangle_test_uv_fixture import hello


def test_hello():
    assert hello() == "wrangle-test-uv-fixture"
