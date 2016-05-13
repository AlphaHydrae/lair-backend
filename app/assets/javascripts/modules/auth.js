angular.module('lair.auth', [ 'base64', 'lair.auth.token', 'lair.storage', 'satellizer', 'ui.gravatar' ])

  .factory('auth', function(appStore, $auth, $log, $rootScope, tokenAuth) {

    var service = {

      authenticate: function(provider, authCredentials) {
        if (provider === 'token') {
          return tokenAuth.authenticate(authCredentials).then(signIn);
        } else {
          return $auth.authenticate(provider).then(signIn);
        }
      },

      unauthenticate: function() {
        $auth.logout().then(function() {
          appStore.remove('auth.user');
          delete service.currentUser;
          delete $rootScope.currentUser;
          $log.debug('User has signed out');
        });
      },

      isAuthenticated: $auth.isAuthenticated,

      updateCurrentUser: function(user) {
        if (user.id == service.currentUser.id) {
          service.currentUser = user;
          $rootScope.currentUser = service.currentUser;
          appStore.set('auth.user', service.currentUser);
        }
      },

      addAuthFunctions: function($scope) {

        $scope.currentUserIs = function() {
          if (!$rootScope.currentUser) {
            return false;
          }

          var requiredRoles = Array.prototype.slice.call(arguments),
              currentUserRoles = $rootScope.currentUser.roles || [];

          return _.intersection(currentUserRoles, requiredRoles).length == requiredRoles.length;
        };
      }
    };

    if ($auth.isAuthenticated()) {
      service.currentUser = appStore.get('auth.user');
      $rootScope.currentUser = service.currentUser;
    }

    function signIn(response) {

      var user = response.data.user;
      service.currentUser = user;
      $rootScope.currentUser = user;
      appStore.set('auth.user', user);

      $log.debug('User ' + user.email + ' has signed in');

      return response;
    }

    return service;
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

  .factory('authInterceptor', function($q, $rootScope) {
    return {
      responseError: function(err) {
        console.log(err.status);

        if (err.status == 401) {
          $rootScope.$broadcast('auth.unauthorized', err);
        } if (err.status == 403) {
          $rootScope.$broadcast('auth.forbidden', err);
        } if (err.status == 404) {
          $rootScope.$broadcast('auth.notFound', err);
        }

        return $q.reject(err);
      }
    };
  })

  .config(function($httpProvider) {
    $httpProvider.interceptors.push('authInterceptor');
  })

  .controller('AuthController', function(auth, $log, $modal, $scope) {

    $scope.isAuthenticated = auth.isAuthenticated;

    $scope.showLoginDialog = function() {

      var modal = $modal.open({
        size: 'sm',
        templateUrl: 'templates/loginDialog.html',
        controller: 'LoginController',
        windowClass: 'loginDialog'
      });

      modal.result.then(undefined, function() {
        $log.debug('User did not sign in');
      });
    };

    $scope.signOut = auth.unauthenticate;
  })

  .controller('LoginController', function(auth, $modalInstance, $scope) {

    function onError(response) {
      $scope.signingIn = false;
      $scope.error = response.data && response.data.message ? response.data.message : 'An error occurred during authentication.';
    }

    $scope.signInWith = function(provider, authCredentials) {
      delete $scope.error;
      $scope.signingIn = true;
      return auth.authenticate(provider, authCredentials).then($modalInstance.close, onError);
    };
  })

;
