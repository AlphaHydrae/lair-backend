angular.module('lair.mediaScans').factory('mediaScans', function() {

  var service = {
    getDuration: function(scan) {

      var endTime;
      if (scan.state == 'analyzed') {
        endTime = moment(scan.analyzedAt).valueOf();
      } else if (scan.state == 'analysisFailed') {
        endTime = moment(scan.analysisFailedAt).valueOf();
      } else if (scan.state == 'failed') {
        endTime = moment(scan.failedAt).valueOf();
      } else if (scan.state == 'canceled') {
        endTime = moment(scan.canceledAt).valueOf();
      } else if (scan.state == 'started' || scan.state == 'scanned' || scan.state == 'processed') {
        endTime = new Date().getTime();
      }

      if (!endTime) {
        return;
      }

      return endTime - moment(scan.createdAt).valueOf();
    }
  };

  return service;
});
