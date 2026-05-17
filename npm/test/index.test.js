// Unit tests for the wrangle-test npm fixture, run by wrangle's
// build_and_publish_npm.yml via `npm test` (node --test). A failing
// test here fails the npm build — proof the test step is executed.

import assert from "node:assert/strict";
import { test } from "node:test";

import { add, hello, slugify } from "../src/index.js";

test("hello returns the package name", () => {
  assert.equal(hello(), "wrangle-test-npm-fixture");
});

test("add sums any number of values", () => {
  assert.equal(add(1, 2, 3), 6);
  assert.equal(add(), 0);
  assert.equal(add(-4, 4), 0);
});

test("add rejects non-finite input", () => {
  assert.throws(() => add(1, "2"), TypeError);
  assert.throws(() => add(Infinity), TypeError);
  assert.throws(() => add(Number.NaN), TypeError);
});

test("slugify normalizes case and whitespace", () => {
  assert.equal(slugify("Hello World"), "hello-world");
  assert.equal(slugify("  Wrangle   Test  "), "wrangle-test");
});

test("slugify rejects empty text", () => {
  assert.throws(() => slugify("   "), /non-empty/);
});
