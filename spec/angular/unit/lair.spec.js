describe("lair", function() {
  beforeEach(module('lair'));

  describe("version", function() {

    it("should be correct", inject(['version', function(version) {
      expect(version).toBe('0.1.0');
    }]));
  });

  describe("environment", function() {

    it("should be test", inject(['environment', function(env) {
      expect(env).toBe('test');
    }]));
  });

  describe("config", function() {

    it("should include Google OAuth2 parameters", inject(['config.googleOAuth2ClientId', 'config.googleOAuth2CallbackUrl', function(clientId, callbackUrl) {
      expect(typeof(clientId)).toBe('string');
      expect(typeof(callbackUrl)).toBe('string');
    }]));
  });
});
