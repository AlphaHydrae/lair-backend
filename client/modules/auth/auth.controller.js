angular.module('lair.auth').controller('AuthCtrl', function(auth, $log, $modal, $scope) {

  $scope.isAuthenticated = auth.isAuthenticated;

  $scope.showLoginDialog = function() {

    var modal = $modal.open({
      size: 'sm',
      templateUrl: '/templates/modules/auth/auth.login.template.html',
      controller: 'LoginCtrl',
      windowClass: 'loginDialog'
    });

    modal.result.then(undefined, function() {
      $log.debug('User did not sign in');
    });
  };

  $scope.signOut = auth.unauthenticate;
});
