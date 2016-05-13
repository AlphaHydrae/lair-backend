angular.module('lair.explorer').controller('YieldGroupDialogCtrl', function(api, auth, $log, $q, $scope) {

  $scope.dateOptions = {
    dateFormat: 'yy-mm-dd',
    maxDate: new Date()
  };

  $scope.yieldData = {
    yieldedAt: new Date()
  };

  $scope.$watch('ownerships', function(value) {
    if (value) {
      _.each(value, function(ownership) {
        var gottenAt = moment(ownership.gottenAt);
        if (!$scope.dateOptions.minDate) {
          $scope.dateOptions.minDate = gottenAt.toDate();
        } else if (gottenAt.isAfter($scope.dateOptions.minDate)) {
          $scope.dateOptions.minDate = gottenAt.toDate();
        }
      });
    }
  }, true);

  api({
    url: '/ownerships',
    params: {
      itemIds: _.pluck($scope.group.items, 'id'),
      userId: auth.currentUser.id,
      owned: true
    }
  }).then(function(res) {
    $scope.ownerships = res.data;
    $log.debug('Found ' + res.data.length + ' ownerships for ' + $scope.group.items.length + ' items (for the current user)');
  });

  $scope.yield = function() {

    $scope.saved = false;

    $q.all(_.map($scope.ownerships, function(ownership) {
      return api({
        method: 'PATCH',
        url: '/ownerships/' + ownership.id,
        data: $scope.yieldData
      }).then(function() {
        var item = _.findWhere($scope.group.items, { id: ownership.itemId });
        if (item) {
          item.ownedByMe = false;
        }
      });
    })).then(function(res) {
      $scope.saved = true;
    });
  };
});
