

angular.module('lair', ['lair.state', 'lair.auth', 'lair.home', 'lair.routes', 'lair.items.edit', 'satellizer'])

  // configuration
  .constant('version', "0.1.0")
  .constant('environment', "test")
  .constant('config.googleOAuth2ClientId', "test")

  // enable debug log unless in production
  .config(['environment', '$logProvider', function(env, $logProvider) {
    $logProvider.debugEnabled(env !== 'production');
  }])

  .config(['config.googleOAuth2ClientId', '$authProvider', function(googleOAuth2ClientId, $authProvider) {
    $authProvider.google({
      clientId: googleOAuth2ClientId
    });
  }])

;
