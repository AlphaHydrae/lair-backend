angular.module('lair.auth').factory('auth', function(appStore, $auth, $log, $rootScope, tokenAuth) {

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

    currentUserIs: function() {
      if (!service.currentUser) {
        return false;
      }

      var requiredRoles = Array.prototype.slice.call(arguments),
          currentUserRoles = service.currentUser.roles || [];

      return _.intersection(currentUserRoles, requiredRoles).length == requiredRoles.length;
    },

    addAuthFunctions: function($scope) {
      $scope.currentUserIs = service.currentUserIs;
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
});
