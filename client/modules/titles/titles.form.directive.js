angular.module('lair.titles').directive('titlesForm', function() {
  return {
    restrict: 'E',
    controller: 'TitlesFormCtrl',
    templateUrl: '/templates/modules/titles/titles.form.template.html',
    scope: {
      record: '=',
      label: '@?',
      helpMessage: '@?',
      placeholder: '=?',
      titleSearch: '&',
      titleSearchWatch: '=?',
      titleRequired: '=?'
    }
  };
}).controller('TitlesFormCtrl', function($scope) {

  _.defaults($scope, {
    label: 'Titles',
    titleRequired: false,
    titleSearchWatch: false
  });

  _.defaults($scope.record, {
    titles: []
  });

  $scope.titleSortOptions = {
    handle: '.move',
    cancel: '' // disable default jquery ui sortable behavior preventing elements of type ":input,button" to be used as handles
  };

  $scope.addTitle = function() {
    $scope.record.titles.push({});
  };

  $scope.removeTitle = function(title) {
    $scope.record.titles.splice($scope.record.titles.indexOf(title), 1);
  };
});
