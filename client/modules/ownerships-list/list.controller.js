angular.module('lair.ownerships.list').controller('OwnershipsListCtrl', function(api, auth, $log, $modal, $scope) {

  $scope.fetchOwnerships = function(table) {

    table.pagination.start = table.pagination.start || 0;
    table.pagination.number = table.pagination.number || 15;

    var params = {
      start: table.pagination.start,
      number: table.pagination.number,
      withItem: 1,
      withUser: 1
    };

    if (table.search.predicateObject) {
      params.search = table.search.predicateObject.$;
    }

    api({
      url: '/ownerships',
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
      gottenAt: new Date(),
      user: auth.currentUser,
      userId: auth.currentUser.id
    };

    $scope.reset();

    var modal = $modal.open({
      controller: 'EditOwnershipCtrl',
      templateUrl: '/templates/modules/ownerships-list/list.editDialog.template.html',
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
      templateUrl: '/templates/modules/ownerships-list/list.editDialog.template.html',
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
});
