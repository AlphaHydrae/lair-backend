angular.module('lair.forms').directive('helpIcon', function() {
  return {
    restrict: 'E',
    template: '<span class="glyphicon glyphicon-question-sign help-icon" popover="{{ helpMessage }}" popover-title="Help: {{ helpTitle }}" popover-trigger="mouseenter mouseleave" popover-append-to-body="true" />',
    scope: {
      helpTitle: '@',
      helpMessage: '@'
    }
  };
});
