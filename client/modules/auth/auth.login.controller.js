angular.module('lair.auth').controller('LoginCtrl', function(auth, $uibModalInstance, $scope) {

  function onError(response) {
    $scope.signingIn = false;
    $scope.error = response.data && response.data.message ? response.data.message : 'An error occurred during authentication.';
  }

  $scope.signInWith = function(provider, authCredentials) {
    delete $scope.error;
    $scope.signingIn = true;
    return auth.authenticate(provider, authCredentials).then($uibModalInstance.close, onError);
  };
});
