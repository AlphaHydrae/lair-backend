angular.module('lair.infinite').controller('InfiniteCtrl', function(api, auth, $scope) {

  $scope.fetchMore = fetchMore;
  $scope.showMore = showMore;

  var state = $scope.infiniteState = {
    initialized: false,
    loading: false,
    noMore: false,
    enabled: true,
    error: false
  };

  $scope.$watch('httpSettings', function(value) {
    if (value && state.initialized) {
      reset();
    }
  }, true);

  var resetting = false;

  function reset() {
    resetting = true;
    state.loading = false;
    state.noMore = false;
    fetchMore();
  }

  function fetchMore() {
    if (state.noMore || !$scope.infiniteOptions || ($scope.infiniteOptions.enabled !== undefined && !$scope.infiniteOptions.enabled)) {
      return;
    }

    state.loading = true;

    var length = resetting ? 0 : $scope.records.length;

    var params = _.extend({}, $scope.httpSettings.params, {
      start: length,
      number: length === 0 ? 60 : 24
    });

    api({
      url: $scope.httpSettings.url,
      params: params
    }).then(addRecords, handleError);
  }

  function showMore() {
    state.enabled = true;
  }

  function handleError() {
    resetting = false;
    $scope.records.length = 0;
    state.error = true;
  }

  function addRecords(res) {

    if (resetting) {
      resetting = false;
      $scope.records.length = 0;
    }

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
});
