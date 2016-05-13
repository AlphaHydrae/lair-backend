angular.module('lair.parts.edit', ['lair.parts.form'])

  .controller('EditPartCtrl', function(api, $log, $modal, $q, $scope, $state, $stateParams) {

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

    $scope.imageSearchesResource = '/parts/' + $stateParams.partId + '/image-searches';
    $scope.mainImageSearchResource = '/parts/' + $stateParams.partId + '/main-image-search';

    api({
      url: '/parts/' + $stateParams.partId,
      params: {
        withItem: 1
      }
    }).then(function(res) {
      $scope.part = parsePart(res.data);
      reset();
      $scope.$broadcast('part', $scope.part);
    }, function(res) {
      $log.warn('Could not fetch part ' + $stateParams.partId);
      $log.debug(res);
    });

    $scope.save = function() {
      api({
        method: 'PATCH',
        url: '/parts/' + $stateParams.partId,
        data: dumpPart(_.omit($scope.modifiedPart, 'item', 'title')),
        params: {
          withItem: 1
        }
      }).then(function(res) {
        $scope.part = parsePart(res.data);
        reset();
        $scope.$broadcast('part', $scope.part);
      }, function(res) {
        $log.warn('Could not update part ' + $stateParams.partId);
        $log.debug(res);
      });
    };

    function reset() {
      $scope.modifiedPart = angular.copy($scope.part);
    }

    $scope.reset = reset;

    $scope.cancel = function() {
      // TODO: go back
      $state.go('home');
    };
  })

;
