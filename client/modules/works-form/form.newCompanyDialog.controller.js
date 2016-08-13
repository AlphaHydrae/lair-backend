angular.module('lair.works.form').controller('NewCompanyCtrl', function(api, $log, $uibModalInstance, $scope) {

  $scope.company = {};

  $scope.save = function() {

    api({
      method: 'POST',
      url: '/companies',
      data: $scope.company
    }).then(function(res) {
      $uibModalInstance.close(res.data);
    });
  };

  $scope.selectExisting = function() {
    $uibModalInstance.close($scope.existingCompany);
  };
});
