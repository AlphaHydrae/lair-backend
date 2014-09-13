angular.module('lair.home', ['lair.api', 'ngTable'])

  .controller('HomeController', ['ApiService', 'ngTableParams', '$scope', function($api, ngTableParams, $scope) {

    $scope.items = [{title:'foo'},{title:'bar'}];

    $scope.tableParams = new ngTableParams({
      page: 1,
      count: 10
    }, {
      total: 0,
      getData: function($defer, params) {
        $api.http({
          method: 'GET',
          url: '/api/items'
        }).then(function(response) {
          $scope.items = response.data;
          $defer.resolve();
        }, $defer.reject);
      }
    });
  }])

;
