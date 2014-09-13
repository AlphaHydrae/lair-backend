
angular.module('lair.auth', ['base64', 'lair.auth.strategy', 'LocalStorageModule', 'ngCookies', 'ui.bootstrap', 'ui.gravatar'])

  .run(['AuthService', function($auth) {
    $auth.checkAuthentication();
  }])

  .service('AuthService', ['AuthStrategiesService', '$base64', '$http', 'localStorageService', '$log', '$q', '$rootScope', function($strategies, $base64, $http, $local, $log, $q, $rootScope) {

    var ready = false,
        service = {};

    service.start = function() {

      // TODO: cache strategy name
      var strategyName = $local.get('auth.strategy');

      if (ready) {
        return $q.when(strategyName);
      }

      return $http({
        method: 'POST',
        url: '/users/auth/start'
      }).then(function() {
        ready = true;
        return strategyName;
      }, function() {
        return $q.reject(new Error('The authentication service is unavailable. Please try again later.'));
      });
    };

    service.checkAuthentication = function() {
      var authPayload = $local.get('auth.payload');
      if (authPayload) {
        service.setAuthentication({ payload: authPayload });
      }
    };

    service.setAuthentication = function(auth) {
      if (!$local.get('auth.payload')) {
        $local.set('auth.strategy', auth.strategyName);
        $local.set('auth.payload', auth.payload);
      }

      var token = auth.payload.token;

      var tokenParts = token.split(/\./),
          decodedToken = JSON.parse($base64.decode(tokenParts[1]));

      var user = { email: decodedToken.iss };
      $rootScope.currentUser = user;

      $log.debug('User ' + user.email + ' signed in');
    };

    service.checkSignedIn = function(strategyName) {
      var auth = { strategyName: strategyName };
      return $q.when(auth).then($strategies.checkSignedIn).then(function(authPayload) {
        auth.payload = authPayload;
        return service.setAuthentication(auth);
      }, function(err) {
        $local.remove('auth.strategy');
        return $q.reject(err);
      });
    };

    service.signIn = function(strategyName, credentials) {
      var auth = { strategyName: strategyName, credentials: credentials };
      return $q.when(auth).then($strategies.signIn).then(function(authPayload) {
        auth.payload = authPayload;
        return service.setAuthentication(auth);
      });
    };

    service.signOut = function() {

      $local.remove('auth.payload');

      var user = $rootScope.currentUser;
      delete $rootScope.currentUser;

      $log.debug('User ' + user.email + ' signed out');
    };

    return service;
  }])

  .controller('AuthController', ['$modal', '$scope', 'AuthService', function($modal, $scope, $auth) {

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

    $scope.signOut = function() {
      $auth.signOut();
    };
  }])
  
  .controller('LoginController', ['$q', '$scope', '$log', '$modalInstance', 'AuthService', 'environment', function($q, $scope, $log, $modalInstance, $auth, env) {

    $scope.environment = env;

    $auth.start().then(function(strategyName) {
      $scope.authReady = true;

      if (strategyName) {
        $scope.signingIn = true;
        $auth.checkSignedIn(strategyName).then(function() {
          $scope.signingIn = false;
        }, function() {
          $scope.signingIn = false;
        });
      }
    }, function() {
      $scope.authReady = false;
    });

    $scope.signInWith = function(strategyName) {
      delete $scope.error;
      $scope.signingIn = true;

      $auth.signIn(strategyName, $scope.authCredentials).then(function() {
        $modalInstance.close();
      }, function(err) {
        $scope.signingIn = false;
        $scope.error = err && err.message ? err.message : 'An error occurred during authentication.';
      });
    };
  }])

;
