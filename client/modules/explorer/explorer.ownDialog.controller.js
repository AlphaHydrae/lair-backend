angular.module('lair.explorer').controller('OwnDialogCtrl', function($scope) {

  $scope.dateOptions = {
    dateFormat: 'yy-mm-dd'
  };

  $scope.ownership = {
    itemId: $scope.item.id,
    gottenAt: new Date()
  };

  $scope.create = function() {
    $scope.$emit('ownership', $scope.ownership, $scope.item);
  };
});
