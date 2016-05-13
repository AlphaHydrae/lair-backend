angular.module('lair.properties').directive('propertiesEditor', function() {
  return {
    restrict: 'E',
    controller: 'PropertiesEditorCtrl',
    controllerAs: 'ctrl',
    templateUrl: '/templates/modules/properties/properties.template.html',
    scope: {
      model: '=model'
    }
  };
});
