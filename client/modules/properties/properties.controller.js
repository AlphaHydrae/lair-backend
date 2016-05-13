angular.module('lair.properties').controller('PropertiesEditorCtrl', function($scope) {

  $scope.propertyType = function(property) {
    if (_.isArray(property.value)) {
      return 'array';
    } else {
      return 'string';
    }
  };

  $scope.taggingChoices = [];

  $scope.addProperty = function() {
    $scope.model.properties.push({});
  };

  $scope.addArrayProperty = function() {
    $scope.model.properties.push({
      value: []
    });
  };

  $scope.removeProperty = function(property) {
    $scope.model.properties.splice($scope.model.properties.indexOf(property), 1);
  };
});
