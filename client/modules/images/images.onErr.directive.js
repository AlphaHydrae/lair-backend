angular.module('lair.images').directive('onErr', function() {
  return {
    restrict: 'A',
    scope: {
      onErr: '&',
      errSubject: '='
    },
    link: function(scope, element) {
      element.bind('error', function() {
        scope.$apply(function() {
          scope.onErr(scope.errSubject);
        });
      });
    }
  };
});
