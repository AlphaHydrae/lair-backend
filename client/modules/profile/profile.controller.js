angular.module('lair.profile').controller('ProfileCtrl', function(api, auth, forms, $scope) {

  $scope.user = _.omit($scope.currentUser, 'activeAt');

  $scope.save = saveProfile;
  $scope.reset = resetModifiedUser;
  $scope.generateAuthToken = generateAuthToken;
  $scope.$watch('user', resetModifiedUser);

  $scope.changed = function() {
    return !forms.dataEquals($scope.user, $scope.modifiedUser);
  };

  function generateAuthToken() {
    api({
      method: 'POST',
      url: '/tokens'
    }).then(function(res) {
      $scope.authToken = res.data.token;
    });
  }

  function saveProfile() {
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
