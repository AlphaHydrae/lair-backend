angular.module('lair.collections.preview', [ 'lair.api' ])

  .directive('collectionPreview', function() {
    return {
      restrict: 'E',
      templateUrl: '/templates/collections-preview.html',
      controller: 'CollectionPreviewCtrl',
      scope: {
        collection: '=',
        autoUpdate: '='
      },
      link: function($scope, element) {

        var e = $(element);
        $scope.countVisibleItems = function() {
          return e.find('.items .item:visible').length;
        };
      }
    };
  })

  .controller('CollectionPreviewCtrl', function(api, auth, explorer, $interval, $scope, $timeout) {

    var newItemsInterval;

    $scope.updatingItems = true;
    $scope.moreItems = false;
    $scope.currentUser = auth.currentUser;

    $scope.show = openExplorerWithItem;
    $scope.random = _.partial(startUpdatingItems, true);
    auth.addAuthFunctions($scope);

    fetchRandomItems();

    $scope.$on('$destroy', stopFetchingItems);

    function openExplorerWithItem(item) {
      stopFetchingItems();
      explorer.open('items', item, { params: { collectionId: $scope.collection.id } });
    }

    function fetchRandomItems() {
      api({
        url: '/items',
        params: {
          random: 1,
          number: 6,
          collectionId: $scope.collection.id
        }
      }).then(function(res) {

        $scope.items = res.data;
        $scope.totalItems = res.pagination().total;

        if ($scope.totalItems > 6) {
          $scope.moreItems = true;
          startUpdatingItems();
        } else {
          $scope.moreItems = false;
          stopFetchingItems();
        }
      });
    }

    function startUpdatingItems(immediate) {
      if (!$scope.autoUpdate) {
        return;
      }

      $scope.updatingItems = true;

      newItemsInterval = $interval(fetchRandomItem, 15000);
      $timeout(stopFetchingItems, 300000);

      if (immediate) {
        fetchRandomItem();
      }
    }

    function fetchRandomItem() {
      api({
        url: '/items',
        params: {
          random: 1,
          number: 1,
          collectionId: $scope.collection.id
        }
      }).then(function(res) {
        if (res.data.length) {
          replaceRandomItem(res.data[0]);
        }
      });
    }

    function replaceRandomItem(item) {
      var indexToReplace = Math.floor(Math.random() * $scope.countVisibleItems());
      $scope.items[indexToReplace] = item;
    }

    function stopFetchingItems() {
      $scope.updatingItems = false;

      if (newItemsInterval) {
        $interval.cancel(newItemsInterval);
      }
    }
  })

;
