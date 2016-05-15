angular.module('lair.works.list').controller('WorksListCtrl', function(explorer, $scope) {
  explorer.openFromLocation($scope);
});
