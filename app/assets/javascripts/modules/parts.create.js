angular.module('lair.parts.create', ['lair.parts.form'])

  .controller('CreatePartCtrl', ['ApiService', '$log', '$modal', '$q', '$scope', '$state', '$stateParams', function($api, $log, $modal, $q, $scope, $state, $stateParams) {

    function parsePart(part) {
      return _.extend({}, part, {
        tags: _.reduce(_.keys(part.tags).sort(), function(memo, key) {
          memo.push({ key: key, value: part.tags[key] });
          return memo;
        }, [])
      });
    }

    function dumpPart(part) {
      return _.extend({}, part, {
        tags: _.reduce(part.tags, function(memo, tag) {
          memo[tag.key] = tag.value;
          return memo;
        }, {})
      });
    }

    $scope.part = parsePart({
      tags: []
    });

    if ($stateParams.itemId) {
      $api.http({
        url: '/api/items/' + $stateParams.itemId
      }).then(function(res) {
        $scope.part.item = res.data;
        $scope.part.itemId = res.data.id;
        reset();
      }, function(err) {
        $log.warn('Could not fetch item ' + $stateParams.itemId);
        $log.debug(err);
      });
    } else {
      reset();
    }

    function reset() {
      $scope.modifiedPart = angular.copy($scope.part);
      $scope.$broadcast('part', $scope.part);
    }

    $scope.imageSearchesResource = '/api/image-searches';

    $scope.save = function() {
      $api.http({
        method: 'POST',
        url: '/api/parts',
        data: dumpPart($scope.modifiedPart)
      }).then(function(res) {
        $state.go('std.parts.edit', { partId: res.data.id });
      }, function(res) {
        $log.warn('Could not update part ' + $stateParams.partId);
        $log.debug(res);
      });
    };

    $scope.cancel = function() {
      if ($stateParams.itemId) {
        $state.go('std.home.item', { itemId: $stateParams.itemId });
      } else {
        $state.go('std.home');
      }
    };
  }])
;
