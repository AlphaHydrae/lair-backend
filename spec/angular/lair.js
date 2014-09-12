

angular.module('lair', ['lair.state', 'lair.auth'])

  // configuration
  .constant('version', "0.1.0")
  .constant('environment', "test")
  .constant('config.googleOAuth2ClientId', "test")
  .constant('config.googleOAuth2CallbackUrl', "/users/auth/google_oauth2/callback")

  // enable debug log unless in production
  .config(['environment', '$logProvider', function(env, $logProvider) {
    $logProvider.debugEnabled(env !== 'production');
  }])

;
