angular.module('lair.images.missing').controller('MissingImagesCtrl', function(api, $log, $modal, $q, $scope) {

  $scope.showAllItems = false;
  $scope.useSameImageForMainItemAndWork = true;

  // TODO: find out why an "all" promise with the two countMissingImages requests doesn't resolve properly
  $q.when()
    .then(_.partial(countMissingImages, 'works'))
    .then(_.partial(countMissingImages, 'items'))
    .then(fetchResourceWithMissingImage);

  $scope.approveAll = function() {

    var promise = $q.when(),
        mainItemHasSameImage = $scope.mainItem && $scope.mainItem.image && $scope.work.image == $scope.mainItem.image;

    if ($scope.work.image && !$scope.work.image.id) {
      promise = promise.then(_.partial(approveImage, $scope.work, 'works', $scope.work.image));
    }

    if (mainItemHasSameImage) {
      promise = promise.then(function(image) {
        return approveImage($scope.mainItem, 'items', { id: image.id });
      });
    }

    _.each($scope.work.items, function(item) {
      if (item.image && !item.image.id && (!mainItemHasSameImage || item != $scope.mainItem)) {
        promise = promise.then(_.partial(approveImage, item, 'items', item.image));
      }
    });

    promise = promise.then(function() {
      if (!countCurrentMissingImages()) {
        fetchResourceWithMissingImage();
      }
    });
  };

  $scope.nextRandomWork = function() {
    fetchResourceWithMissingImage();
  };

  $scope.countOutstandingApprovals = function() {
    var n = 0;

    if ($scope.work) {
      if ($scope.work.image && !$scope.work.image.id) {
        n++;
      }

      if ($scope.work.items) {
        n += _.reduce($scope.work.items, function(memo, item) {
          return memo + (item.image && !item.image.id ? 1 : 0);
        }, 0);
      }
    }

    return n;
  };

  $scope.approveImage = function(subject, resource) {
    approveImage(subject, resource, subject.image);
  };

  function approveImage(subject, resource, imageData) {
    return api({
      method: 'PATCH',
      url: '/' + resource + '/' + subject.id,
      data: {
        image: imageData
      }
    }).then(function(res) {
      subject.image = res.data.image;
      $scope[resource + 'Count'] -= 1;
      return subject.image;
    }, function(res) {
      $log.warn('Could not update image of ' + resource + ' ' + subject.id);
      $log.debug(res);
    });
  }

  $scope.selectImage = function(subject, resource) {
    $scope.imageSearchResource = resource;
    $scope.imageSearchResourceId = subject.id;

    modal = $modal.open({
      controller: 'SelectImageCtrl',
      templateUrl: '/templates/modules/images-select/select.template.html',
      scope: $scope,
      size: 'lg'
    });

    modal.result.then(function(image) {
      subject.image = image;
      if ($scope.useSameImageForMainItemAndWork && resource == 'works' && $scope.mainItem) {
        $scope.mainItem.image = image;
      } else if ($scope.useSameImageForMainItemAndWork && resource == 'items' && subject == $scope.mainItem) {
        $scope.work.image = image;
      }
    });
  };

  function setMainItem() {
    if ($scope.work.items.length == 1) {
      $scope.mainItem = $scope.work.items[0];
    } else {
      $scope.mainItem = _.findWhere($scope.work.items, { start: 1 });
    }
  }

  function fetchResourceWithMissingImage() {
    if (!$scope.worksCount && !$scope.itemsCount) {
      $log.debug('No work or item is missing an image; nothing to do');
      return;
    }

    delete $scope.work;

    var resource = $scope.itemsCount ? 'items' : 'works',
        params = {
          image: 0,
          imageFromSearch: 1,
          random: 1,
          number: 1
        };

    if (resource == 'works') {
      $log.debug('No item is missing an image; fetching a random work');
    } else if (resource == 'items') {
      params.withWork = 1;
      $log.debug('Fetching a random item missing an image');
    }

    api({
      url: '/' + resource,
      params: params
    }).then(function(res) {
      $scope.work = resource == 'items' ? res.data[0].work : res.data[0];
      return fetchItems();
    }, function(res) {
      $log.warn('Could not fetch random ' + resource + ' missing an image');
      $log.debug(res);
    });
  }

  function fetchItems(start) {

    start = start || 0;

    $scope.work.items = [];

    return api({
      url: '/items',
      params: {
        workId: $scope.work.id,
        imageFromSearch: 1,
        start: start,
        number: 100
      }
    }).then(function(res) {
      $scope.work.items = $scope.work.items.concat(res.data);
      $log.debug('Fetched items ' + (res.pagination().start + 1) + '-' + (res.pagination().end + 1) + ' for work ' + $scope.work.id);
      if (res.pagination().hasMorePages()) {
        return fetchItems(start + res.data.length);
      } else {
        setMainItem();
      }
    }, function(res) {
      $log.warn('Could not fetch items for work ' + $scope.work.id);
      $log.debug(res);
    });
  }

  function countCurrentMissingImages() {
    var n = 0;

    if ($scope.work) {
      if (!$scope.work.image || !$scope.work.image.id) {
        n++;
      }

      if ($scope.work.items) {
        n += _.reduce($scope.work.items, function(memo, item) {
          return memo + (!item.image || !item.image.id ? 1 : 0);
        }, 0);
      }
    }

    return n;
  }

  function countMissingImages(resource) {
    return api({ // TODO: change to HEAD request when this issue is fixed: https://github.com/intridea/grape/issues/1014
      url: '/' + resource,
      params: {
        image: 0,
        random: 1,
        number: 1
      }
    }).then(function(res) {

      var count = parseInt(res.headers('X-Pagination-Filtered-Total'), 10);
      $scope[resource + 'Count'] = count;

      $log.debug('Number of ' + resource + ' missing an image: ' + count);
    }, function(res) {
      $log.warn('Could not count ' + resource + ' that do not have an image');
      $log.debug(res);
    });
  }
});
