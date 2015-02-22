angular.module('lair.images.missing', [])

  .filter('filterParts', function() {
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

  .controller('MissingImagesCtrl', ['ApiService', '$log', '$modal', '$q', '$scope', function($api, $log, $modal, $q, $scope) {

    // TODO: find out why an "all" promise with the two countMissingImages requests doesn't resolve properly
    $q.when()
      .then(_.partial(countMissingImages, 'items'))
      .then(_.partial(countMissingImages, 'parts'))
      .then(fetchResourceWithMissingImage);

    $scope.approveImage = function(subject, resource) {
      $api.http({
        method: 'PATCH',
        url: '/api/' + resource + '/' + subject.id,
        data: {
          image: subject.image
        }
      }).then(function(res) {
        subject.image = res.data.image;
      }, function(res) {
        $log.warn('Could not update image of ' + resource + ' ' + subject.id);
        $log.debug(res);
      });
    };

    $scope.selectImage = function(subject, resource) {
      $scope.imageSearchSubject = subject;
      $scope.imageSearchResource = '/api/' + resource + '/' + subject.id + '/imageSearch';

      modal = $modal.open({
        controller: 'SelectImageCtrl',
        templateUrl: '/templates/selectImageDialog.html',
        scope: $scope,
        size: 'lg'
      });

      modal.result.then(function(image) {
        subject.image = image;
      });
    };

    function fetchResourceWithMissingImage() {
      if (!$scope.itemsCount && !$scope.partsCount) {
        $log.debug('No item or part is missing an image; nothing to do');
        return;
      }

      var resource = $scope.partsCount ? 'parts' : 'items',
          params = {
            image: 0,
            imageFromSearch: 1,
            random: 1,
            pageSize: 1
          };

      if (resource == 'items') {
        $log.debug('No part is missing an image; fetching a random item');
      } else if (resource == 'parts') {
        params.item = 1;
        $log.debug('Fetching a random item part missing an image');
      }

      $api.http({
        url: '/api/' + resource,
        params: params
      }).then(function(res) {
        $scope.item = resource == 'parts' ? res.data[0].item : res.data[0];
        return fetchItemParts();
      }, function(res) {
        $log.warn('Could not fetch random ' + resource + ' missing an image');
        $log.debug(res);
      });
    }

    function fetchItemParts(startPage) {

      var page = startPage || 1,
          pageSize = 100;

      $scope.item.parts = [];

      return $api.http({
        url: '/api/parts',
        params: {
          itemId: $scope.item.id,
          imageFromSearch: 1,
          page: page,
          pageSize: pageSize
        }
      }).then(function(res) {
        $scope.item.parts = $scope.item.parts.concat(res.data);
        $log.debug('Fetched parts ' + res.pagination().startNumber + '-' + res.pagination().endNumber + ' for item ' + $scope.item.id);
        if (res.pagination().hasMorePages()) {
          return fetchItemParts(page + 1);
        }
      }, function(res) {
        $log.warn('Could not fetch parts for item ' + $scope.item.id);
        $log.debug(res);
      });
    }

    function countMissingImages(resource) {
      var promise = $api.http({
        method: 'HEAD',
        url: '/api/' + resource,
        params: {
          image: 0,
          random: 1,
          pageSize: 1
        }
      });

      promise = promise.then(function(res) {

        var count = parseInt(res.headers('X-Pagination-FilteredTotal'), 10);
        $scope[resource + 'Count'] = count;

        $log.debug('Number of ' + resource + ' missing an image: ' + count);
      }, function(res) {
        $log.warn('Could not count ' + resource + ' that do not have an image');
        $log.debug(res);
      });

      return promise;
    }
  }])
;
