angular.module('lair.home', ['lair.api', 'ngTable'])

  .controller('HomeController', ['ApiService', 'ngTableParams', '$scope', function($api, ngTableParams, $scope) {

    $scope.tableParams = new ngTableParams({
      page: 1,
      count: 10
    }, {
      total: 0,
      getData: function($defer, params) {
        $api.http({
          method: 'GET',
          url: '/api/items',
          params: {
            page: params.page(),
            pageSize: params.count()
          }
        }).then(function(response) {
          params.total(response.headers('X-Pagination-Total'));
          $defer.resolve(response.data);
        }, $defer.reject);
      }
    });
  }])

;
