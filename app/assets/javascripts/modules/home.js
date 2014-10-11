angular.module('lair.home', ['lair.api', 'infinite-scroll', 'ngTable'])

  .run(function() {
    angular.module('infinite-scroll').value('THROTTLE_MILLISECONDS', 1000);
  })

  .controller('HomeController', ['ApiService', '$modal', 'ngTableParams', '$scope', function($api, $modal, ngTableParams, $scope) {

    var page = 1,
        index = 0;

    $scope.items = [];
    $scope.itemsLoading = false;
    $scope.noMoreItems = false;

    function addItems(items) {
      _.each(items, function(item) {
        if (index !== 0 && index % 6 === 0) {
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
          pageSize: 12
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

    $scope.show = function(item) {

      $scope.item = item;

      var modal = $modal.open({
        controller: 'ItemDialogController',
        templateUrl: '/templates/itemDialog.html',
        scope: $scope,
        size: 'lg'
      });

      modal.result.then(undefined, function() {
        delete $scope.item;
      });
    };
  }])

  .controller('ItemDialogController', ['ApiService', '$scope', function($api, $scope) {

    $api.http({
      method: 'GET',
      url: '/api/parts',
      params: {
        itemKey: $scope.item.key
      }
    }).then(function(response) {

      $scope.item.parts = _.reduce(response.data, function(memo, part) {

        var tabName = part.publisher || 'Other';
        if (!_.findWhere(memo, { name: tabName })) {
          memo.push({ name: tabName, parts: [] });
        }

        var tabData = _.findWhere(memo, { name: tabName });
        tabData.parts.push(part);

        return memo;
      }, []);
      console.log($scope.item.parts);
    });
  }])

;
