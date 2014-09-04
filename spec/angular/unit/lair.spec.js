
describe("lair", function() {
  beforeEach(module('lair'));

  describe("version", function() {

    var actualVersion;
    beforeEach(inject(['version', function(version) {
      actualVersion = version;
    }]));

    it("should be correct", function() {
      expect(actualVersion).toBe('0.1.0');
    });
  });

  describe("environment", function() {

    var actualEnvironment;
    beforeEach(function() {
      inject(['environment', function(environment) {
        actualEnvironment = environment;
      }]);
    });

    it("should be test", function() {
      expect(actualEnvironment).toBe('test');
    });
  });
});
