angular.module('lair.items.edit').controller('EditItemCtrl', function(api, $log, $q, $scope, $state, $stateParams) {

  function parseItem(item) {
    return _.extend({}, item, {
      properties: _.reduce(_.keys(item.properties).sort(), function(memo, key) {
        memo.push({ key: key, value: item.properties[key] });
        return memo;
      }, [])
    });
  }

  function dumpItem(item) {
    return _.extend({}, item, {
      properties: _.reduce(item.properties, function(memo, property) {
        memo[property.key] = property.value;
        return memo;
      }, {})
    });
  }

  $scope.imageSearchResource = 'items';
  $scope.imageSearchResourceId = $stateParams.itemId;

  api({
    url: '/items/' + $stateParams.itemId,
    params: {
      withWork: 1
    }
  }).then(function(res) {
    $scope.item = parseItem(res.data);
    reset();
    $scope.$broadcast('item', $scope.item);
  }, function(res) {
    $log.warn('Could not fetch item ' + $stateParams.itemId);
    $log.debug(res);
  });

  $scope.save = function() {
    api({
      method: 'PATCH',
      url: '/items/' + $stateParams.itemId,
      data: dumpItem(_.omit($scope.modifiedItem, 'work', 'title')),
      params: {
        withWork: 1
      }
    }).then(function(res) {
      $scope.item = parseItem(res.data);
      reset();
      $scope.$broadcast('item', $scope.item);
    }, function(res) {
      $log.warn('Could not update item ' + $stateParams.itemId);
      $log.debug(res);
    });
  };

  function reset() {
    $scope.modifiedItem = angular.copy($scope.item);
  }

  $scope.reset = reset;

  $scope.cancel = function() {
    // TODO: go back
    $state.go('home');
  };
});
