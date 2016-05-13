angular.module('lair.busy').factory('busy', function() {

  var service = function($scope, busy) {
    if (busy === undefined) {
      return $scope.busy || 0;
    }

    if (!busy) {
      delete $scope.busy;
      return;
    }

    if (!$scope.busy) {
      $scope.busy = 0;
    }

    $scope.busy += (busy === true ? 1 : busy);
  };

  return service;
});
