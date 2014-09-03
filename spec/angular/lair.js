

angular.module('lair', ['lair.state', 'lair.auth'])
  .value('version', "0.1.0")
  .value('config.environment', "test")
  .value('config.googleOAuth2ClientId', "test")
  .value('config.googleOAuth2CallbackUrl', "/users/auth/google_oauth2/callback")
;
