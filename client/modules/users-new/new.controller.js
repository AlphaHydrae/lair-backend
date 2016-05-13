angular.module('lair.users.new').controller('NewUserCtrl', function(api, forms, $scope, $state, users) {

  $scope.user = {
    active: true
  };

  $scope.modifiedUser = angular.copy($scope.user);

  $scope.save = createUser;

  $scope.changed = function() {
    return !forms.dataEquals($scope.user, $scope.modifiedUser);
  };

  function createUser() {
    api({
      method: 'POST',
      url: '/users',
      data: $scope.modifiedUser
    }).then(function(res) {
      users.clearCache();
      $state.go('users.edit', { id: res.data.id });
    });
  }
});
