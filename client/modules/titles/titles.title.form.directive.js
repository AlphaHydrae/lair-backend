angular.module('lair.titles').directive('titleForm', function() {
  return {
    restrict: 'E',
    templateUrl: '/templates/modules/titles/titles.title.form.template.html',
    controller: 'TitleFormCtrl',
    scope: {
      title: '=',
      titleIndex: '=',
      titleParent: '=',
      titleSearch: '=',
      titleSearchWatch: '=?',
      deletable: '=',
      onRemove: '&'
    }
  };
}).controller('TitleFormCtrl', function(api, languages, $q, $scope) {

  _.defaults($scope, {
    titleRequired: false,
    titleSearchWatch: false
  });

  languages.addLanguages($scope);

  $scope.$watchGroup([ 'title.text', 'titleSearchWatch' ], function(values, oldValues) {

    var title = values[0],
        watch = values[1];

    if (title !== oldValues[0] || watch !== oldValues[1]) {
      $scope.titleExists = false;
      $scope.titleSearch({ text: title }).then(function(exists) {
        $scope.titleExists = exists;
      });
    }
  });
});
