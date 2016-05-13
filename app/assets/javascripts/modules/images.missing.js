angular.module('lair.images.missing', [])

  .filter('onlyPartsWithImage', function() {
    return function(parts, scope) {
      if (scope.showAllParts) {
        return parts;
      } else {
        return _.filter(parts, function(part) {
          return !part.image || !part.image.id;
        });
      }
    };
  })

  .controller('MissingImagesCtrl', function(api, $log, $modal, $q, $scope) {

    $scope.showAllParts = false;
    $scope.useSameImageForMainPartAndItem = true;

    // TODO: find out why an "all" promise with the two countMissingImages requests doesn't resolve properly
    $q.when()
      .then(_.partial(countMissingImages, 'items'))
      .then(_.partial(countMissingImages, 'parts'))
      .then(fetchResourceWithMissingImage);

    $scope.approveAll = function() {

      var promise = $q.when(),
          mainPartHasSameImage = $scope.mainPart && $scope.mainPart.image && $scope.item.image == $scope.mainPart.image;

      if ($scope.item.image && !$scope.item.image.id) {
        promise = promise.then(_.partial(approveImage, $scope.item, 'items', $scope.item.image));
      }

      if (mainPartHasSameImage) {
        promise = promise.then(function(image) {
          return approveImage($scope.mainPart, 'parts', { id: image.id });
        });
      }

      _.each($scope.item.parts, function(part) {
        if (part.image && !part.image.id && (!mainPartHasSameImage || part != $scope.mainPart)) {
          promise = promise.then(_.partial(approveImage, part, 'parts', part.image));
        }
      });

      promise = promise.then(function() {
        if (!countCurrentMissingImages()) {
          fetchResourceWithMissingImage();
        }
      });
    };

    $scope.nextRandomItem = function() {
      fetchResourceWithMissingImage();
    };

    $scope.countOutstandingApprovals = function() {
      var n = 0;

      if ($scope.item) {
        if ($scope.item.image && !$scope.item.image.id) {
          n++;
        }

        if ($scope.item.parts) {
          n += _.reduce($scope.item.parts, function(memo, part) {
            return memo + (part.image && !part.image.id ? 1 : 0);
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
      $scope.imageSearchesResource = '/' + resource + '/' + subject.id + '/image-searches';
      $scope.mainImageSearchResource = '/' + resource + '/' + subject.id + '/main-image-search';

      modal = $modal.open({
        controller: 'SelectImageCtrl',
        templateUrl: '/templates/selectImageDialog.html',
        scope: $scope,
        size: 'lg'
      });

      modal.result.then(function(image) {
        subject.image = image;
        if ($scope.useSameImageForMainPartAndItem && resource == 'items' && $scope.mainPart) {
          $scope.mainPart.image = image;
        } else if ($scope.useSameImageForMainPartAndItem && resource == 'parts' && subject == $scope.mainPart) {
          $scope.item.image = image;
        }
      });
    };

    function setMainPart() {
      if ($scope.item.parts.length == 1) {
        $scope.mainPart = $scope.item.parts[0];
      } else {
        $scope.mainPart = _.findWhere($scope.item.parts, { start: 1 });
      }
    }

    function fetchResourceWithMissingImage() {
      if (!$scope.itemsCount && !$scope.partsCount) {
        $log.debug('No item or part is missing an image; nothing to do');
        return;
      }

      delete $scope.item;

      var resource = $scope.partsCount ? 'parts' : 'items',
          params = {
            image: 0,
            imageFromSearch: 1,
            random: 1,
            number: 1
          };

      if (resource == 'items') {
        $log.debug('No part is missing an image; fetching a random item');
      } else if (resource == 'parts') {
        params.withItem = 1;
        $log.debug('Fetching a random item part missing an image');
      }

      api({
        url: '/' + resource,
        params: params
      }).then(function(res) {
        $scope.item = resource == 'parts' ? res.data[0].item : res.data[0];
        return fetchItemParts();
      }, function(res) {
        $log.warn('Could not fetch random ' + resource + ' missing an image');
        $log.debug(res);
      });
    }

    function fetchItemParts(start) {

      start = start || 0;

      $scope.item.parts = [];

      return api({
        url: '/parts',
        params: {
          itemId: $scope.item.id,
          imageFromSearch: 1,
          start: start,
          number: 100
        }
      }).then(function(res) {
        $scope.item.parts = $scope.item.parts.concat(res.data);
        $log.debug('Fetched parts ' + (res.pagination().start + 1) + '-' + (res.pagination().end + 1) + ' for item ' + $scope.item.id);
        if (res.pagination().hasMorePages()) {
          return fetchItemParts(start + res.data.length);
        } else {
          setMainPart();
        }
      }, function(res) {
        $log.warn('Could not fetch parts for item ' + $scope.item.id);
        $log.debug(res);
      });
    }

    function countCurrentMissingImages() {
      var n = 0;

      if ($scope.item) {
        if (!$scope.item.image || !$scope.item.image.id) {
          n++;
        }

        if ($scope.item.parts) {
          n += _.reduce($scope.item.parts, function(memo, part) {
            return memo + (!part.image || !part.image.id ? 1 : 0);
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
  })
;
