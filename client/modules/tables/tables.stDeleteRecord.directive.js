angular.module('lair.tables').directive('stDeleteRecord', function($log) {
  return {
  restrict: 'AE',
    require: '^stTable',
    scope: {
      callback: '&'
    },
    link: function(scope, element, attrs, ctrl) {

      var table = ctrl.tableState();

      element.on('click', function(ev) {
        scope.callback.call().then(function(result) {
          if (result) {
            $log.debug('Refresh table due to deleted record');
            ctrl.pipe();
          }
        });
      });
    }
  };
});
