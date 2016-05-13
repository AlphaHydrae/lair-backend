angular.module('lair.status', [ 'lair.api' ])

  .controller('ImageUploadErrorDialogCtrl', function(api, $scope) {
    api({
      url: '/images/' + $scope.selectedImage.id + '/uploadError'
    }).then(function(res) {
      $scope.uploadError = res.data;
    });
  })

  .controller('StatusCtrl', function(api, $modal, $scope, $timeout) {

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
      api({
        method: 'PATCH',
        url: '/images/' + image.id,
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
      api({
        method: 'DELETE',
        url: '/images/' + image.id
      }).then(function() {

        updateImageStats();
        $scope.orphanedImages.splice($scope.orphanedImages.indexOf(image), 1);

        if (!$scope.orphanedImages.length) {
          $scope.hideOrphanedImages();
        }
      });
    };

    function updateImageStats() {
      api({
        url: '/stats/images'
      }).then(function(res) {
        $scope.imageStats = res.data;

        if (res.data.uploading) {
          $timeout(updateImageStats, 3000);
        }
      });
    }

    function fetchImageUploadErrors(start) {
      start = start || 0;

      api({
        url: '/images',
        params: {
          orphan: 0,
          state: 'upload_failed',
          number: 10,
          start: start
        }
      }).then(function(res) {
        $scope.imageUploadErrors = $scope.imageUploadErrors.concat(res.data);

        if (res.pagination().hasMorePages()) {
          fetchImageUploadErrors(start + res.data.length);
        }
      });
    }

    function fetchOrphanedImages(start) {
      start = start || 0;

      api({
        url: '/images',
        params: {
          orphan: 1,
          number: 10,
          start: start
        }
      }).then(function(res) {
        $scope.orphanedImages = $scope.orphanedImages.concat(res.data);

        if (res.pagination().hasMorePages()) {
          fetchOrphanedImages(start + res.data.length);
        }
      });
    }
  })

;
