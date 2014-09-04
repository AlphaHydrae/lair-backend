
angular.module('lair.auth', ['lair.auth.google', 'lair.auth.test', 'ui.bootstrap', 'ui.gravatar', 'ngCookies', 'base64', 'LocalStorageModule'])

  .run(['AuthService', 'localStorageService', function($auth, $local) {
    var authPayload = $local.get('authPayload');
    if (authPayload) {
      $auth.signIn(authPayload);
    }
  }])

  .service('AuthService', ['$base64', '$rootScope', 'localStorageService', function($base64, $rootScope, $local) {

    var service = {
      ready: false
    };

    service.signIn = function(response) {
      if (!$local.get('authPayload')) {
        $local.set('authPayload', response);
      }

      var token = response.token;
      $rootScope.authToken = token;

      var tokenParts = token.split(/\./),
          decodedToken = JSON.parse($base64.decode(tokenParts[1]));

      var user = { email: decodedToken.iss };
      $rootScope.currentUser = user;

      console.log(user.email + ' signed in');
    };

    service.signOut = function() {

      $local.remove('authPayload');

      var user = $rootScope.currentUser;
      delete $rootScope.authToken;
      delete $rootScope.currentUser;

      console.log(user.email + ' signed out');
    };

    service.setReady = function(ready) {
      service.ready = ready;
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
        console.log('failure');
      });
    };

    $scope.signOut = function() {
      $auth.signOut();
    };
  }])
  
  .controller('LoginController', ['$http', '$q', '$scope', '$modalInstance', 'AuthService', 'GoogleAuthService', 'TestAuthService', 'environment', function($http, $q, $scope, $modalInstance, $auth, $googleAuth, $testAuth, env) {

    $scope.environment = env;

    if ($auth.ready) {
      $scope.authReady = true;
    } else {
      $http({
        method: 'POST',
        url: '/users/auth/start'
      }).then(function() {
        $auth.setReady(true);
        $scope.authReady = true;
        console.log($scope.authReady);
      }, function() {
        $scope.error = 'The authentication service is down. Please try again later.';
      });
    }

    var strategies = {
      google: $googleAuth,
      test: $testAuth
    };

    function getStrategy(name) {
      return strategies[name] ? $q.when(strategies[name]) : $q.reject(new Error('Unknown authentication strategy: ' + name));
    }

    function signIn(authPayload) {
      $auth.signIn(authPayload);
      delete $scope.signingIn;
      $modalInstance.close();
    }

    $scope.signInWith = function(strategyName) {
      delete $scope.error;
      $scope.signingIn = true;

      getStrategy(strategyName).then(function(strategy) {
        strategy.signIn($scope.authCredentials).then(signIn, function(err) {
          delete $scope.signingIn;
          $scope.error = err && err.message ? err.message : 'An error occurred during authentication.';
        });
      });
    };
  }])
;
