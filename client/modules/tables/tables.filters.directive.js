angular.module('lair.tables').directive('tableFilters', function($log) {
  return {
  restrict: 'E',
    require: '^stTable',
    scope: {
      filters: '='
    },
    link: function(scope, element, attrs, ctrl) {
      scope.$watch('filters', function(value, oldValue) {
        if (value !== oldValue) {
          ctrl.pipe();
        }
      }, true);
    }
  };
});
