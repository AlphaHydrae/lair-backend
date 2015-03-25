angular.module('lair.ownerships', [])

  .controller('OwnershipListCtrl', ['ApiService', '$log', '$modal', '$scope', function($api, $log, $modal, $scope) {

    $scope.fetchOwnerships = function(table) {

      table.pagination.start = table.pagination.start || 0;
      table.pagination.number = table.pagination.number || 15;

      var pageSize = table.pagination.number,
          page = table.pagination.start / pageSize + 1,
          params = {
            page: page,
            pageSize: pageSize,
            withPart: 1,
            withUser: 1
          };

      if (table.search.predicateObject) {
        params.search = table.search.predicateObject.$;
      }

      $api.http({
        url: '/api/ownerships',
        params: params
      }).then(function(res) {
        $scope.ownerships = res.data;
        table.pagination.numberOfPages = res.pagination().numberOfPages;
      }, function(err) {
        $log.warn('Could not fetch ownerships');
        $log.debug(err);
      });
    };

    $scope.addOwnership = function() {

      $scope.ownership = {
        gottenAt: new Date()
      };

      $scope.reset();

      var modal = $modal.open({
        controller: 'EditOwnershipCtrl',
        templateUrl: '/templates/editOwnershipDialog.html',
        scope: $scope,
        size: 'lg'
      });

      modal.result.finally(function() {
        delete $scope.ownership;
        delete $scope.modifiedOwnership;
      });
    };

    $scope.edit = function(ownership) {

      $scope.ownership = ownership;
      $scope.reset();

      var modal = $modal.open({
        controller: 'EditOwnershipCtrl',
        templateUrl: '/templates/editOwnershipDialog.html',
        scope: $scope,
        size: 'lg'
      });

      modal.result.then(function(result) {
        if (result == 'delete') {
          $scope.ownerships.splice($scope.ownerships.indexOf(ownership), 1);
        } else {
          _.extend(_.findWhere($scope.ownerships, { id: result.id }), result);
        }
      }).finally(function() {
        delete $scope.ownership;
        delete $scope.modifiedOwnership;
      });
    };

    $scope.reset = function() {
      $scope.modifiedOwnership = angular.copy($scope.ownership);
      $scope.$broadcast('reset');
    };
  }])

  .controller('EditOwnershipCtrl', ['ApiService', '$log', '$modalInstance', '$scope', function($api, $log, $modalInstance, $scope) {

    $scope.dateOptions = {
      dateFormat: 'yy-mm-dd'
    };

    $scope.$on('reset', function() {
      resetParts();
      resetUsers();
    });

    var firstCheck = true;
    $scope.$watchGroup([ 'modifiedOwnership.partId', 'modifiedOwnership.userId', 'modifiedOwnership.gottenAt' ], checkForExistingOwnership);

    function checkForExistingOwnership(newValues) {
      if (_.compact(newValues).length < 3 || firstCheck) {
        firstCheck = false;
        delete $scope.ownershipAlreadyExists;
        return;
      }

      firstCheck = false;

      $api.http({
        url: '/api/ownerships',
        params: {
          pageSize: 1,
          partId: newValues[0],
          userId: newValues[1]
        }
      }).then(function(res) {
        $scope.ownershipAlreadyExists = !!res.data.length && (!$scope.ownership.id || res.data[0].id != $scope.ownership.id);
      }, function(err) {
        $log.warn('Could not fetch ownerships for part "' + newValues[0] + '" and user "' + newValues[1] + '"');
        $log.debug(err);
      });
    }

    $scope.fetchParts = function(search) {
      if (!search || !search.trim().length) {
        resetParts();
        return;
      }

      $api.http({
        url: '/api/parts',
        params: {
          pageSize: 100,
          search: search
        }
      }).then(function(res) {
        $scope.parts = res.data;
      }, function(res) {
        $log.warn('Could not fetch parts matching "' + search + '"');
        $log.debug(res);
      });
    };

    $scope.fetchUsers = function(search) {
      if (!search || !search.trim().length) {
        resetUsers();
        return;
      }

      $api.http({
        url: '/api/users',
        params: {
          pageSize: 100,
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
      $api.http({
        method: $scope.ownership.id ? 'PATCH' : 'POST',
        url: $scope.ownership.id ? '/api/ownerships/' + $scope.ownership.id : '/api/ownerships',
        data: $scope.modifiedOwnership,
        params: {
          withPart: 1,
          withUser: 1
        }
      }).then(function(res) {
        $modalInstance.close(res.data);
      }, function(err) {
        $log.warn('Could not update ownership "' + $scope.ownership.id + '"');
        $log.debug(err);
      });
    };

    $scope.delete = function() {
      if (!confirm('Are you sure you want to delete ownership of "' + $scope.ownership.part.title.text + '" by ' + $scope.ownership.user.email + '?')) {
        return;
      }

      $api.http({
        method: 'DELETE',
        url: '/api/ownerships/' + $scope.ownership.id
      }).then(function() {
        $modalInstance.close('delete');
      }, function(err) {
        $log.warn('Could not delete ownership "' + $scope.ownership.id + '"');
        $log.debug(err);
      });
    };

    function resetParts() {
      $scope.parts = $scope.ownership && $scope.ownership.partId ? [ $scope.ownership.part ] : [];
    }

    function resetUsers() {
      $scope.users = $scope.ownership && $scope.ownership.userId ? [ $scope.ownership.user ] : [];
    }
  }])
;
