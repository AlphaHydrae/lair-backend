angular.module('lair.items.create', ['lair.items.form'])

  .controller('CreateItemCtrl', ['ApiService', '$log', '$scope', '$state', '$stateParams', function($api, $log, $scope, $state, $stateParams) {

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

    $scope.item = parseItem({
      category: 'manga',
      titles: [ {} ],
      relationships: [],
      links: [],
      tags: []
    });

    $scope.imageSearchResource = '/api/imageSearches';

    reset();

    $scope.save = function() {
      $api.http({
        method: 'POST',
        url: '/api/items',
        data: dumpItem($scope.modifiedItem)
      }).then(function(res) {
        $state.go('std.items.edit', { itemId: res.data.id });
      }, function(response) {
        $log.warn('Could not create item');
        $log.debug(response);
      });
    };

    $scope.reset = reset;

    function reset() {
      $scope.modifiedItem = angular.copy($scope.item);
      $scope.$broadcast('item', $scope.item);
    }

    $scope.cancel = function() {
      $state.go('std.home');
    };
  }])
;
