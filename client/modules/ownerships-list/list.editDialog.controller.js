angular.module('lair.ownerships.list').controller('EditOwnershipCtrl', function(api, $log, $uibModalInstance, $scope) {

  $scope.dateOptions = {
    dateFormat: 'yy-mm-dd'
  };

  $scope.$on('reset', function() {
    resetItems();
    resetUsers();
  });

  var firstCheck = true;
  $scope.$watchGroup([ 'modifiedOwnership.itemId', 'modifiedOwnership.userId', 'modifiedOwnership.gottenAt' ], checkForExistingOwnership);

  function checkForExistingOwnership(newValues) {
    if (_.compact(newValues).length < 3 || firstCheck) {
      firstCheck = false;
      delete $scope.ownershipAlreadyExists;
      return;
    }

    firstCheck = false;

    api({
      url: '/ownerships',
      params: {
        number: 1,
        itemId: newValues[0],
        userId: newValues[1]
      }
    }).then(function(res) {
      $scope.ownershipAlreadyExists = !!res.data.length && (!$scope.ownership.id || res.data[0].id != $scope.ownership.id);
    }, function(err) {
      $log.warn('Could not fetch ownerships for item "' + newValues[0] + '" and user "' + newValues[1] + '"');
      $log.debug(err);
    });
  }

  $scope.fetchItems = function(search) {
    if (!search || !search.trim().length) {
      resetItems();
      return;
    }

    api({
      url: '/items',
      params: {
        number: 100,
        search: search
      }
    }).then(function(res) {
      $scope.items = res.data;
    }, function(res) {
      $log.warn('Could not fetch items matching "' + search + '"');
      $log.debug(res);
    });
  };

  $scope.fetchUsers = function(search) {
    if (!search || !search.trim().length) {
      resetUsers();
      return;
    }

    api({
      url: '/users',
      params: {
        number: 100,
        search: search
      }
    }).then(function(res) {
      $scope.users = res.data;
    }, function(res) {
      $log.warn('Could not fetch users matching "' + search + '"');
      $log.debug(res);
    });
  };

  $scope.ownershipChanged = function() {
    return !angular.equals($scope.ownership, $scope.modifiedOwnership);
  };

  $scope.save = function() {
    api({
      method: $scope.ownership.id ? 'PATCH' : 'POST',
      url: $scope.ownership.id ? '/ownerships/' + $scope.ownership.id : '/ownerships',
      data: $scope.modifiedOwnership,
      params: {
        withItem: 1,
        withUser: 1
      }
    }).then(function(res) {
      $uibModalInstance.close(res.data);
    }, function(err) {
      $log.warn('Could not update ownership "' + $scope.ownership.id + '"');
      $log.debug(err);
    });
  };

  $scope.delete = function() {
    if (!confirm('Are you sure you want to delete ownership of "' + $scope.ownership.item.title.text + '" by ' + $scope.ownership.user.email + '?')) {
      return;
    }

    api({
      method: 'DELETE',
      url: '/ownerships/' + $scope.ownership.id
    }).then(function() {
      $uibModalInstance.close('delete');
    }, function(err) {
      $log.warn('Could not delete ownership "' + $scope.ownership.id + '"');
      $log.debug(err);
    });
  };

  function resetItems() {
    $scope.items = $scope.ownership && $scope.ownership.itemId ? [ $scope.ownership.item ] : [];
  }

  function resetUsers() {
    $scope.users = $scope.ownership && $scope.ownership.userId ? [ $scope.ownership.user ] : [];
  }
});
