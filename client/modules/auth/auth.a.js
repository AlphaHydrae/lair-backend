angular.module('lair.auth', [ 'base64', 'lair.storage', 'satellizer', 'ui.gravatar' ])

  .config(function($httpProvider) {
    $httpProvider.interceptors.push('authInterceptor');
  })

  .run(function(auth, $rootScope, $state) {

    auth.addAuthFunctions($rootScope);

    $rootScope.$on('auth.unauthorized', function(event, err) {
      auth.unauthenticate();
    });

    // TODO: handle forbidden
    /*$rootScope.$on('auth.forbidden', function(event, err) {
      if (!err.config.custom || !err.config.custom.ignoreForbidden) {
        $state.go('error', { type: 'forbidden' });
      }
    });*/

    // TODO: handle not found
    /*$rootScope.$on('auth.notFound', function(event, err) {
      if (!err.config.custom || !err.config.custom.ignoreNotFound) {
        $state.go('error', { type: 'notFound' });
      }
    });*/
  })

;
