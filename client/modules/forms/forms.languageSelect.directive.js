angular.module('lair.forms').directive('languageSelect', function() {
  return {
    restrict: 'E',
    scope: {
      languages: '=',
      model: '=ngModel',
      multiple: '='
    },
    templateUrl: '/templates/modules/forms/forms.languageSelect.template.html',
    controller: function($scope) {

      $scope.updateSelection = function(selected) {
        if ($scope.multiple) {
          $scope.model = _.pluck(selected, 'tag');
        } else {
          $scope.model = selected.tag;
        }
      };

      $scope.groupCommonLanguages = function(language) {
        return language.used ? 'Common' : 'Other';
      };
    }
  };
});
