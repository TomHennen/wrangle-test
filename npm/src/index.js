// Disposable npm test fixture for wrangle integration tests.
//
// The functions here exist so the package has real behavior for the
// unit tests in test/ to exercise — wrangle's npm build
// (build_and_publish_npm.yml) runs `npm test` before it packs the
// tarball.

/** Return the fixture's package name. */
export function hello() {
  return "wrangle-test-npm-fixture";
}

/**
 * Return the sum of every argument.
 * Throws TypeError if any argument is not a finite number.
 */
export function add(...values) {
  for (const value of values) {
    if (typeof value !== "number" || !Number.isFinite(value)) {
      throw new TypeError(`add() expects finite numbers, got ${String(value)}`);
    }
  }
  return values.reduce((total, value) => total + value, 0);
}

/**
 * Return `text` as a lowercase, single-hyphen-joined slug.
 * Throws Error when `text` has no word characters.
 */
export function slugify(text) {
  const words = String(text)
    .toLowerCase()
    .trim()
    .split(/\s+/)
    .filter(Boolean);
  if (words.length === 0) {
    throw new Error("slugify() requires non-empty text");
  }
  return words.join("-");
}
