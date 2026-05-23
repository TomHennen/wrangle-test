// Unit tests for the npm fixture, run by wrangle's build_and_publish_npm.yml
// via `npm test` (node --test). A failing test fails the npm build — proof
// the test step is wired up and executed. Excluded from the published
// tarball by package.json's `files` allowlist.

const test = require('node:test');
const assert = require('node:assert/strict');

const ms = require('./index.js');

test('fixture re-exports the ms parser', () => {
  assert.equal(typeof ms, 'function');
});

test('ms parses duration strings to milliseconds', () => {
  assert.equal(ms('2 days'), 172800000);
  assert.equal(ms('1m'), 60000);
  assert.equal(ms('100'), 100);
});

test('ms formats milliseconds back to strings', () => {
  assert.equal(ms(60000), '1m');
  assert.equal(ms(172800000), '2d');
});

test('ms returns undefined for unparseable input', () => {
  assert.equal(ms('not a duration'), undefined);
});
