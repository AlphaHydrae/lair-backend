angular.module('lair.infinite').directive('infinite', function() {
  return {
    restrict: 'E',
    templateUrl: '/templates/modules/infinite/infinite.template.html',
    controller: 'InfiniteCtrl',
    transclude: true,
    scope: {
      records: '=',
      httpSettings: '=',
      infiniteOptions: '=',
      onFetched: '&?',
      onRecordsUpdated: '&?'
    }
  };
});
