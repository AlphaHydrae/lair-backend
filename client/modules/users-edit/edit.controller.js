angular.module('lair.users.edit').controller('EditUserCtrl', function(api, auth, forms, $scope, $stateParams) {

  api({
    url: '/users/' + $stateParams.id
  }).then(function(res) {
    $scope.user = res.data;
  });

  $scope.save = updateUser;
  $scope.reset = resetModifiedUser;
  $scope.$watch('user', resetModifiedUser);

  $scope.changed = function() {
    return !forms.dataEquals($scope.user, $scope.modifiedUser);
  };

  function updateUser() {
    api({
      method: 'PATCH',
      url: '/users/' + $scope.user.id,
      data: $scope.modifiedUser
    }).then(function(res) {
      $scope.user = res.data;
      auth.updateCurrentUser(res.data);
    });
  }

  function resetModifiedUser() {
    $scope.modifiedUser = angular.copy($scope.user);
  }
});
