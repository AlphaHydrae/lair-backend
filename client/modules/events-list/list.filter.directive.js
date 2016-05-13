angular.module('lair.events.list').directive('filterEvents', function() {
  return {
    restrict: 'E',
    require: '^stTable',
    templateUrl: '/templates/modules/events-list/list.filter.template.html',
    scope: {
      filters: '='
    },
    link: function($scope, element, attr, ctrl) {

      var lastValue;

      $scope.eventResources = [ '', 'collections', 'items', 'works', 'ownerships', 'people' ];

      $scope.$watch('filters', function(value) {
        if (value) {
          if (lastValue) {

            var table = ctrl.tableState();
            table.pagination.start = 0;

            ctrl.pipe();
          } else {
            lastValue = value;
          }
        }
      }, true);
    }
  };
});
