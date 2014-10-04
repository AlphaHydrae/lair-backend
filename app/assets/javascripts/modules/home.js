angular.module('lair.home', ['lair.api', 'infinite-scroll', 'ngTable'])

  .run(function() {
    angular.module('infinite-scroll').value('THROTTLE_MILLISECONDS', 1000);
  })

  .controller('HomeController', ['ApiService', 'ngTableParams', '$scope', function($api, ngTableParams, $scope) {

    var page = 1,
        index = 0;

    $scope.items = [];
    $scope.itemsLoading = false;
    $scope.noMoreItems = false;

    function addItems(items) {
      _.each(items, function(item) {
        if (index !== 0 && index % 4 === 0) {
          $scope.items.push({ separator: true });
        }
        $scope.items.push(item);
        index++;
      });
    }

    $scope.getNextItems = function() {
      if ($scope.noMoreItems) {
        return;
      }

      $scope.itemsLoading = true;

      $api.http({
        method: 'GET',
        url: '/api/items',
        params: {
          page: page,
          pageSize: 8
        }
      }).then(function(response) {
        if (response.data.length) {
          page++;
          $scope.itemsLoading = false;
          addItems(response.data);
        } else {
          $scope.noMoreItems = true;
        }
        //params.total(response.headers('X-Pagination-Total'));
      });
    };

    /*$scope.tableParams = new ngTableParams({
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
    });*/
  }])

;
