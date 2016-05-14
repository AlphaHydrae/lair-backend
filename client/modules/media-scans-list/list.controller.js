angular.module('lair.mediaScans.list').controller('MediaScansListCtrl', function($scope, showMediaScanDialog, tables) {

  tables.create($scope, 'mediaScansList', {
    url: '/media/scans',
    params: {
      include: 'source'
    }
  });

  $scope.columns = $scope.currentUserIs('admin') ? 6 : 5;

  $scope.scanDuration = function(scan) {
    return (scan.analyzedAt ? moment(scan.analyzedAt).valueOf() : new Date().getTime()) - moment(scan.createdAt).valueOf();
  };

  $scope.showMediaScan = function(scan) {
    showMediaScanDialog.open($scope, {
      mediaScanId: scan.id
    });
  };
});
