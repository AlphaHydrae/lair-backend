angular.module('lair.infinite', [ 'infinite-scroll', 'lair.api', 'lair.auth' ])

  .run(function() {
    angular.module('infinite-scroll').value('THROTTLE_MILLISECONDS', 1000);
  })

  .directive('infinite', function() {
    return {
      restrict: 'E',
      templateUrl: '/templates/infinite.html',
      controller: 'InfiniteCtrl',
      transclude: true,
      scope: {
        records: '=',
        httpSettings: '=',
        infiniteOptions: '=',
        onFetched: '&'
      }
    };
  })

  .controller('InfiniteCtrl', function(api, auth, $scope) {

    $scope.fetchMore = fetchMore;
    $scope.showMore = showMore;

    var state = $scope.infiniteState = {
      initialized: false,
      loading: false,
      noMore: false,
      enabled: true,
    };

    $scope.$watch('httpSettings', function(value) {
      if (value && state.initialized) {
        reset();
      }
    }, true);

    function reset() {
      $scope.records.length = 0;
      state.loading = false;
      state.noMore = false;
      fetchMore();
    }

    function fetchMore() {
      if (state.noMore || !$scope.infiniteOptions || ($scope.infiniteOptions.enabled !== undefined && !$scope.infiniteOptions.enabled)) {
        return;
      }

      state.loading = true;

      var params = _.extend({}, $scope.httpSettings.params, {
        start: $scope.records.length,
        number: $scope.records.length === 0 ? 60 : 24
      });

      api({
        url: $scope.httpSettings.url,
        params: params
      }).then(addRecords);
    }

    function showMore() {
      state.enabled = true;
    }

    function addRecords(res) {

      $scope.onFetched({ res: res });

      if (!state.initialized && !auth.currentUser) {
        state.enabled = false;
      }

      state.initialized = true;
      state.total = res.pagination().total;

      if (res.data.length) {
        _.each(res.data, function(record) {
          $scope.records.push(record);
        });
      }

      if (!res.pagination().hasMorePages()) {
        state.noMore = true;
      }

      state.loading = false;
    }
  })

;
