
angular.module('lair.auth', ['lair.auth.google', 'ui.bootstrap', 'ui.gravatar', 'ngCookies', 'base64', 'LocalStorageModule'])

  .run(['AuthService', 'localStorageService', function($auth, $local) {
    var authPayload = $local.get('authPayload');
    if (authPayload) {
      $auth.signIn(authPayload);
    }
  }])

  .service('AuthService', ['$base64', '$rootScope', 'localStorageService', function($base64, $rootScope, $local) {

    var service = {};

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
  
  .controller('LoginController', ['$q', '$scope', '$modalInstance', 'AuthService', 'GoogleAuthService', function($q, $scope, $modalInstance, $auth, $googleAuth) {

    var strategies = {
      google: $googleAuth
    };

    function getStrategy(name) {
      return strategies[name] ? $q.when(strategies[name]) : $q.reject(new Error('Unknown authentication strategy: ' + name));
    }

    function signIn(authPayload) {
      $auth.signIn(authPayload);
      $modalInstance.close();
    }

    $scope.signInWith = function(strategyName) {

      getStrategy(strategyName).then(function(strategy) {
        strategy.signIn().then(signIn, function(err) {
          $scope.error = err && err.message ? err.message : 'An error occurred during authentication.';
        });
      })
    };
  }])
;
