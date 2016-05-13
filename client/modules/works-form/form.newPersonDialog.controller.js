angular.module('lair.works.form').controller('NewPersonCtrl', function(api, $log, $modalInstance, $scope) {

  $scope.newPerson = {};
  $scope.personAlreadyExists = true;
  $scope.alreadyExistingPerson = null;

  $scope.$watchGroup([ 'newPerson.firstNames', 'newPerson.lastName', 'newPerson.pseudonym' ], _.throttle(checkForExistingPerson, 1000));

  function checkForExistingPerson(newValues) {
    if ($scope.newPersonForm.$invalid) {
      $scope.personAlreadyExists = false;
      $scope.alreadyExistingPerson = null;
      return;
    }

    api({
      url: '/people',
      params: _.extend({
        firstNames: '',
        lastName: '',
        pseudonym: ''
      }, _.pick($scope.newPerson, 'firstNames', 'lastName', 'pseudonym'))
    }).then(function(res) {
      $scope.alreadyExistingPerson = res.data.length ? res.data[0] : null;
      $scope.personAlreadyExists = !!$scope.alreadyExistingPerson;
    }, function(err) {
      $log.warn('Could not find people for ' + JSON.stringify(newValues));
      $log.debug(err);
    });
  }

  $scope.save = function() {

    delete $scope.validationError;

    api({
      method: 'POST',
      url: '/people',
      data: $scope.newPerson
    }).then(onSuccess, onError);
  };

  $scope.selectExistingPerson = function() {
    $modalInstance.close($scope.alreadyExistingPerson);
  };

  function onSuccess(res) {
    $modalInstance.close(res.data);
  }

  function onError(res) {
    if (res.status === 422) {
      $scope.personAlreadyExists = true;
    } else {
      $log.warn('Could not create person');
      $log.debug(res);
    }
  }
});
