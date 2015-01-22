
angular.module('lair.auth', ['base64', 'lair.auth.token', 'LocalStorageModule', 'satellizer', 'ui.bootstrap', 'ui.gravatar'])

  .factory('AuthService', ['$auth', 'localStorageService', '$log', '$rootScope', 'TokenAuthService', function($auth, $local, $log, $rootScope, $tokenAuth) {

    function signIn(response) {

      var user = response.data.user;
      $rootScope.currentUser = user;
      $local.set('auth.user', user);

      $log.debug('User ' + user.email + ' has signed in');

      return response;
    }

    return {

      authenticate: function(provider, authCredentials) {
        if (provider === 'token') {
          return $tokenAuth.authenticate(authCredentials).then(signIn);
        } else {
          return $auth.authenticate(provider).then(signIn);
        }
      },

      unauthenticate: function() {
        $auth.logout().then(function() {
          $local.remove('auth.user');
          delete $rootScope.currentUser;
          $log.debug('User has signed out');
        });
      },

      isAuthenticated: $auth.isAuthenticated,

      checkAuthentication: function() {
        if ($auth.isAuthenticated()) {
          $rootScope.currentUser = $local.get('auth.user');
        }
      }
    };
  }])

  .run(['AuthService', function($auth) {
    $auth.checkAuthentication();
  }])

  .controller('AuthController', ['AuthService', '$log', '$modal', '$scope', function($auth, $log, $modal, $scope) {

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

    $scope.signOut = $auth.unauthenticate;
  }])

  .controller('LoginController', ['AuthService', '$modalInstance', '$scope', function($auth, $modalInstance, $scope) {

    function onError(response) {
      $scope.signingIn = false;
      $scope.error = response.data && response.data.message ? response.data.message : 'An error occurred during authentication.';
    }

    $scope.signInWith = function(provider, authCredentials) {
      delete $scope.error;
      $scope.signingIn = true;
      return $auth.authenticate(provider, authCredentials).then($modalInstance.close, onError);
    };
  }])

;
