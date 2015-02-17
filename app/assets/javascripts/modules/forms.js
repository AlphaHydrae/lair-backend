angular.module('lair.forms', [])

  .directive('languageSelect', [function() {
    return {
      restrict: 'E',
      scope: {
        languages: '=',
        model: '=ngModel'
      },
      templateUrl: '/templates/selectLanguage.html',
      controller: ['$scope', function($scope) {

        $scope.updateSelection = function(language) {
          $scope.model = language.tag;
        };

        $scope.groupCommonLanguages = function(language) {
          return language.used ? 'Common' : 'Other';
        };
      }]
    };
  }])
;
