angular.module('lair.items.edit', ['lair.items.form'])

  .controller('EditItemController', function(api, $log, $scope, $state, $stateParams) {

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

    $scope.imageSearchesResource = '/items/' + $stateParams.itemId + '/image-searches';
    $scope.mainImageSearchResource = '/items/' + $stateParams.itemId + '/main-image-search';

    api({
      url: '/items/' + $stateParams.itemId
    }).then(function(response) {
      $scope.item = parseItem(response.data);
      reset();
      $scope.$broadcast('item', $scope.item);
    });

    $scope.save = function() {
      api({
        method: 'PATCH',
        url: '/items/' + $stateParams.itemId,
        data: dumpItem($scope.modifiedItem)
      }).then(function(response) {
        $scope.item = parseItem(response.data);
        reset();
        $scope.$broadcast('item', $scope.item);
      }, function(response) {
        $log.warn('Could not update item ' + $stateParams.itemId);
        $log.debug(response);
      });
    };

    $scope.reset = reset;

    function reset() {
      $scope.modifiedItem = angular.copy($scope.item);
      $scope.$broadcast('item', $scope.item);
    }

    $scope.cancel = function() {
      // TODO: go back
      $state.go('home');
    };
  })

;
