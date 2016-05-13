angular.module('lair.explorer').controller('ItemGroupCtrl', function($scope) {
  $scope.currentUserOwnsAny = function(items) {
    return !!_.find(items, function(item) {
      return item.ownedByMe;
    });
  };
});
