angular.module('lair.collections.preview').controller('CollectionPreviewCtrl', function(api, auth, explorer, $interval, $scope, $timeout) {

  var newElementsInterval;

  $scope.updatingElements = true;
  $scope.moreElements = false;
  $scope.currentUser = auth.currentUser;
  $scope.elementsResource = $scope.collection.defaultFilters.resource || 'works';
  $scope.elementsParams = _.omit($scope.collection.defaultFilters, 'resource');

  $scope.show = openExplorerWithElement;
  $scope.random = _.partial(startUpdatingElements, true);
  auth.addAuthFunctions($scope);

  fetchRandomElements();
  fetchResourceCount('works');
  fetchResourceCount('items');

  $scope.$on('$destroy', stopFetchingElements);

  function openExplorerWithElement(element) {
    stopFetchingElements();
    if ($scope.elementsResource == 'works') {
      explorer.open('works', element, { params: { collectionId: $scope.collection.id } });
    } else if ($scope.elementsResource == 'items') {
      explorer.open('items', element, { params: { collectionId: $scope.collection.id } });
    } else if ($scope.elementsResource == 'ownerships') {
      explorer.open('items', element.item, { params: { collectionId: $scope.collection.id } });
    }
  }

  function fetchRandomElements() {
    api({
      url: '/' + $scope.elementsResource,
      params: _.extend({}, $scope.elementsParams, {
        random: 1,
        number: 6,
        collectionId: $scope.collection.id,
        withItem: 1
      })
    }).then(function(res) {

      $scope.elements = res.data;

      var totalElements = res.pagination().total;
      if (totalElements > 6) {
        $scope.moreElements = true;
        startUpdatingElements();
      } else {
        $scope.moreElements = false;
        stopFetchingElements();
      }
    });
  }

  function fetchResourceCount(resource) {
    api({
      url: '/' + resource,
      params: {
        number: 1,
        collectionId: $scope.collection.id
      }
    }).then(function(res) {
      $scope['total' + inflection.capitalize(resource)] = res.pagination().total;
    });
  }

  function startUpdatingElements(immediate) {
    if (!$scope.autoUpdate) {
      return;
    }

    $scope.updatingElements = true;

    newElementsInterval = $interval(fetchRandomElement, 15000);
    $timeout(stopFetchingElements, 300000);

    if (immediate) {
      fetchRandomElement();
    }
  }

  function fetchRandomElement() {
    api({
      url: '/' + $scope.elementsResource,
      params: _.extend({}, $scope.elementsParams, {
        random: 1,
        number: 1,
        collectionId: $scope.collection.id,
        withItem: 1
      })
    }).then(function(res) {
      if (res.data.length) {
        replaceRandomElement(res.data[0]);
      }
    });
  }

  function replaceRandomElement(element) {
    var indexToReplace = Math.floor(Math.random() * $scope.countVisibleElements());
    $scope.elements[indexToReplace] = element;
  }

  function stopFetchingElements() {
    $scope.updatingElements = false;

    if (newElementsInterval) {
      $interval.cancel(newElementsInterval);
    }
  }
});
