
describe("Version", function() {

  var actualVersion;

  beforeEach(module('lair'));

  beforeEach(inject(['version', function(version) {
    actualVersion = version;
  }]));

  it("should be correct", function() {
    expect(actualVersion).toBe('0.1.0');
  });
});
