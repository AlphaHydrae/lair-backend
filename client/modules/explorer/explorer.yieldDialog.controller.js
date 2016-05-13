angular.module('lair.explorer').controller('YieldDialogCtrl', function(api, auth, $scope) {

  $scope.dateOptions = {
    dateFormat: 'yy-mm-dd',
    maxDate: new Date()
  };

  $scope.$watch('ownership', function(value) {
    if (value && !value.yieldedAt) {
      value.yieldedAt = new Date();
      $scope.dateOptions.minDate = moment(value.gottenAt).toDate();
    }
  });

  api({
    url: '/ownerships',
    params: {
      itemId: $scope.item.id,
      userId: auth.currentUser.id,
      owned: true
    }
  }).then(function(res) {
    $scope.ownerships = res.data;

    if (res.data.length) {
      $scope.ownership = res.data[0];
    }
  });

  $scope.yield = function() {

    $scope.saved = false;

    api({
      method: 'PATCH',
      url: '/ownerships/' + $scope.ownership.id,
      data: {
        yieldedAt: moment($scope.ownership.yieldedAt).toISOString()
      }
    }).then(function(res) {
      $scope.saved = true;
    });
  };
});
