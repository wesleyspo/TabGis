'use strict';

const DEFAULT_MIN = 3;

function normalizeGeocodeQuery(q) {
  return String(q ?? '').trim();
}

function geocodeQueryTooShort(q, minLen = DEFAULT_MIN) {
  return normalizeGeocodeQuery(q).length < minLen;
}

module.exports = {
  normalizeGeocodeQuery,
  geocodeQueryTooShort,
  DEFAULT_MIN,
};
