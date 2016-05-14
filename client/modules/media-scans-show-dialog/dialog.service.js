angular.module('lair.mediaScans.showDialog').factory('showMediaScanDialog', function($modal) {

  var service = {
    open: function($scope, options) {
      options = _.extend({}, options);

      var scope = $scope.$new();
      _.extend(scope, _.pick(options, 'mediaScan', 'mediaScanId'));

      var modal = $modal.open({
        size: 'lg',
        scope: scope,
        controller: 'ShowMediaScanDialogCtrl',
        templateUrl: '/templates/modules/media-scans-show-dialog/dialog.template.html'
      });

      return modal.result;
    }
  };

  return service;
}).controller('ShowMediaScanDialogCtrl', function(api, $modalInstance, $scope) {

  if (!$scope.mediaScan && $scope.mediaScanId) {
    fetchMediaScan($scope.mediaScanId);
  }

  $scope.scanDuration = function(scan) {
    return (scan.analyzedAt ? moment(scan.analyzedAt).valueOf() : new Date().getTime()) - moment(scan.createdAt).valueOf();
  };

  $scope.retry = function() {
    api({
      method: 'POST',
      url: '/media/scans/' + $scope.mediaScan.id + '/retry'
    }).then(function() {
      $modalInstance.dismiss();
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
