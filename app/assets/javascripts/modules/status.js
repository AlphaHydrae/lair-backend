angular.module('lair.status', [ 'lair.api' ])

  .controller('ImageUploadErrorDialogCtrl', [ 'ApiService', '$scope', function(api, $scope) {
    api.http({
      url: '/api/images/' + $scope.selectedImage.id + '/uploadError'
    }).then(function(res) {
      $scope.uploadError = res.data;
    });
  }])

  .controller('StatusCtrl', [ 'ApiService', '$modal', '$scope', '$timeout', function(api, $modal, $scope, $timeout) {

    updateImageStats();

    $scope.showUploadError = function(image) {
      $scope.selectedImage = image;
      $modal.open({
        scope: $scope,
        size: 'lg',
        controller: 'ImageUploadErrorDialogCtrl',
        templateUrl: '/templates/imageUploadErrorDialog.html'
      });
    };

    $scope.showImageUploadErrors = function() {
      $scope.imageUploadErrors = [];
      fetchImageUploadErrors();
    };

    $scope.hideImageUploadErrors = function() {
      delete $scope.imageUploadErrors;
    };

    $scope.retryImageUpload = function(image) {
      api.http({
        method: 'PATCH',
        url: '/api/images/' + image.id,
        data: {
          state: 'created'
        }
      }).then(function() {

        updateImageStats();
        $scope.imageUploadErrors.splice($scope.imageUploadErrors.indexOf(image), 1);

        if (!$scope.imageUploadErrors.length) {
          $scope.hideImageUploadErrors();
        }
      });
    };

    $scope.showOrphanedImages = function() {
      $scope.orphanedImages = [];
      fetchOrphanedImages();
    };

    $scope.hideOrphanedImages = function() {
      delete $scope.orphanedImages;
    };

    $scope.deleteOrphanedImage = function(image) {
      api.http({
        method: 'DELETE',
        url: '/api/images/' + image.id
      }).then(function() {

        updateImageStats();
        $scope.orphanedImages.splice($scope.orphanedImages.indexOf(image), 1);

        if (!$scope.orphanedImages.length) {
          $scope.hideOrphanedImages();
        }
      });
    };

    function updateImageStats() {
      api.http({
        url: '/api/stats/images'
      }).then(function(res) {
        $scope.imageStats = res.data;

        if (res.data.uploading) {
          $timeout(updateImageStats, 3000);
        }
      });
    }

    function fetchImageUploadErrors(page) {
      page = page || 1;

      api.http({
        url: '/api/images',
        params: {
          orphan: 0,
          state: 'upload_failed',
          pageSize: 10,
          page: page
        }
      }).then(function(res) {
        $scope.imageUploadErrors = $scope.imageUploadErrors.concat(res.data);

        if (res.pagination().hasMorePages()) {
          fetchImageUploadErrors(++page);
        }
      });
    }

    function fetchOrphanedImages(page) {
      page = page || 1;

      api.http({
        url: '/api/images',
        params: {
          orphan: 1,
          pageSize: 10,
          page: page
        }
      }).then(function(res) {
        $scope.orphanedImages = $scope.orphanedImages.concat(res.data);

        if (res.pagination().hasMorePages()) {
          fetchOrphanedImages(++page);
        }
      });
    }
  }])

;
