angular.module('lair', [
  'angularMoment',
  'ngSanitize',
  'satellizer',
  'smart-table',
  'ui.bootstrap',
  'ui.date',
  'ui.select',
  'ui.sortable',
  'lair.state',
  'lair.auth',
  'lair.home',
  'lair.people',
  'lair.routes',
  'lair.images',
  'lair.images.missing',
  'lair.items.create',
  'lair.items.edit',
  'lair.parts.create',
  'lair.parts.edit',
  'lair.ownerships'
])

  // configuration
  .constant('version', "5.0.0")
  .constant('environment', "test")
  .constant('config.googleOAuth2ClientId', "test")

  // enable debug log unless in production
  .config(['environment', '$logProvider', function(env, $logProvider) {
    $logProvider.debugEnabled(env !== 'production');
  }])

  // satellizer
  .config(['config.googleOAuth2ClientId', '$authProvider', function(googleOAuth2ClientId, $authProvider) {
    $authProvider.google({
      clientId: googleOAuth2ClientId
    });
  }])

  // angular-ui-select
  .config(function(uiSelectConfig) {
    uiSelectConfig.theme = 'bootstrap';
  })
;
