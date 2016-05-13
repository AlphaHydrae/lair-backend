angular.module('lair.works.form').controller('NewCompanyCtrl', function(api, $log, $modalInstance, $scope) {

  $scope.company = {};

  $scope.save = function() {

    api({
      method: 'POST',
      url: '/companies',
      data: $scope.company
    }).then(function(res) {
      $modalInstance.close(res.data);
    });
  };

  $scope.selectExisting = function() {
    $modalInstance.close($scope.existingCompany);
  };
});
