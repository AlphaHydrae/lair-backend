
angular.module('lair.auth', ['base64', 'lair.auth.token', 'LocalStorageModule', 'satellizer', 'ui.bootstrap', 'ui.gravatar'])

  .run(['$auth', 'localStorageService', '$rootScope', function($auth, $local, $rootScope) {
    if ($auth.isAuthenticated()) {
      $rootScope.currentUser = $local.get('auth.user');
    }
  }])

  .controller('AuthController', ['$auth', 'localStorageService', '$log', '$modal', '$scope', '$rootScope', function($auth, $local, $log, $modal, $scope, $rootScope) {

    $scope.isAuthenticated = $auth.isAuthenticated;

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
      $auth.logout().then(function() {
        $local.remove('auth.user');
        delete $rootScope.currentUser;
        $log.debug('User has signed out');
      });
    };
  }])

  .controller('LoginController', ['$auth', 'environment', '$rootScope', '$scope', 'localStorageService', '$log', '$modalInstance', 'TokenAuthService', function($auth, env, $rootScope, $scope, $local, $log, $modalInstance, $tokenAuth) {

    $scope.environment = env;

    function signIn(response) {
      $log.debug('User ' + response.data.user.email + ' has signed in');
      $rootScope.currentUser = response.data.user;
      $local.set('auth.user', response.data.user);
      $modalInstance.close();
    }

    function onError(response) {
      $scope.signingIn = false;
      $scope.error = response.data && response.data.message ? response.data.message : 'An error occurred during authentication.';
    }

    $scope.signInWith = function(provider) {
      delete $scope.error;
      $scope.signingIn = true;

      if (provider === 'token') {
        $tokenAuth.authenticate($scope.authToken).then(signIn, onError);
      } else {
        $auth.authenticate(provider).then(signIn, onError);
      }
    };
  }])

;
