angular.module('lair.mediaScans.list').controller('MediaScansListCtrl', function(mediaScans, $scope, showMediaScanDialog, tables) {

  tables.create($scope, 'mediaScansList', {
    url: '/media/scans',
    params: {
      include: 'source'
    }
  });

  $scope.columns = $scope.currentUserIs('admin') ? 6 : 5;

  $scope.scanDuration = mediaScans.getDuration;
  $scope.scanIsInProgress = mediaScans.isInProgress;

  $scope.showMediaScan = function(scan) {
    showMediaScanDialog.open($scope, {
      mediaScanId: scan.id
    });
  };
});
