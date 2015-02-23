angular.module('lair.items.edit', ['lair.items.form'])

  .controller('EditItemController', ['ApiService', '$log', '$scope', '$state', '$stateParams', function($api, $log, $scope, $state, $stateParams) {

    function parseItem(item) {
      return _.extend({}, item, {
        tags: _.reduce(_.keys(item.tags).sort(), function(memo, key) {
          memo.push({ key: key, value: item.tags[key] });
          return memo;
        }, [])
      });
    }

    function dumpItem(item) {
      return _.extend({}, item, {
        tags: _.reduce(item.tags, function(memo, tag) {
          memo[tag.key] = tag.value;
          return memo;
        }, {})
      });
    }

    $api.http({
      url: '/api/items/' + $stateParams.itemId
    }).then(function(response) {
      $scope.item = parseItem(response.data);
      $scope.$broadcast('item', $scope.item);
    });

    $scope.save = function() {
      $api.http({
        method: 'PATCH',
        url: '/api/items/' + $stateParams.itemId,
        data: dumpItem($scope.modifiedItem)
      }).then(function(response) {
        $scope.item = parseItem(response.data);
        $scope.$broadcast('item', $scope.item);
      }, function(response) {
        $log.warn('Could not update item ' + $stateParams.itemId);
        $log.debug(response);
      });
    };

    $scope.cancel = function() {
      $state.go('std.home.item', { itemId: $stateParams.itemId });
    };
  }])
;
