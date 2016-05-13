angular.module('lair.tables').controller('PaginationCtrl', function($scope) {

  $scope.directPageLinks = [];

  $scope.$watchGroup([ 'currentPage', 'numPages' ], function(values) {

    var currentPage = values[0],
        numPages = values[1];

    if (currentPage === undefined || numPages === undefined) {
      $scope.directPageLinks = [];
      return;
    }

    if (numPages <= 7 || currentPage <= 4) {
      $scope.directPageLinks = _.times(numPages < 7 ? numPages : 7, function(i) {
        return i + 1;
      });
    } else if (currentPage + 3 > numPages) {
      $scope.directPageLinks = _.times(7, function(i) {
        return numPages - 6 + i;
      });
    } else {
      $scope.directPageLinks = _.times(7, function(i) {
        return currentPage - 3 + i;
      });
    }
  });

});
