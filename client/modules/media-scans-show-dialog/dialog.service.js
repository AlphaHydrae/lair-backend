angular.module('lair.mediaScans.showDialog').factory('showMediaScanDialog', function($uibModal) {

  var service = {
    open: function($scope, options) {
      options = _.extend({}, options);

      var scope = $scope.$new();
      _.extend(scope, _.pick(options, 'mediaScan', 'mediaScanId'));

      var modal = $uibModal.open({
        size: 'lg',
        scope: scope,
        controller: 'ShowMediaScanDialogCtrl',
        templateUrl: '/templates/modules/media-scans-show-dialog/dialog.template.html'
      });

      return modal.result;
    }
  };

  return service;
}).controller('ShowMediaScanDialogCtrl', function(api, mediaScans, $uibModalInstance, $scope) {

  if (!$scope.mediaScan && $scope.mediaScanId) {
    fetchMediaScan($scope.mediaScanId);
  }

  $scope.scanDuration = mediaScans.getDuration;

  $scope.retry = function() {
    api({
      method: 'POST',
      url: '/media/scans/' + $scope.mediaScan.id + '/retry'
    }).then(function() {
      $uibModalInstance.dismiss();
    });
  };

  function fetchMediaScan(id) {
    api({
      url: '/media/scans/' + id,
      params: {
        include: [ 'errors', 'source' ]
      }
    }).then(function(res) {
      $scope.mediaScan = res.data;
    });
  }
});
