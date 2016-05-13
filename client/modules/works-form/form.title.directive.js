angular.module('lair.works.form').directive('workTitle', function() {
  return {
    restrict: 'E',
    templateUrl: '/templates/modules/works-form/form.title.template.html',
    controller: function(api, $scope) {

      api({
        url: '/languages'
      }).then(function(response) {
        $scope.languages = response.data;
      });

      var ignoreFirstTitleChange = true;
      $scope.$watch('title.text', function(value) {
        if (ignoreFirstTitleChange) {
          ignoreFirstTitleChange = false;
          return;
        }

        checkTitle(value);
      });

      var ignoreFirstCategoryChange = true;
      $scope.$watch('category', function(value) {
        if (ignoreFirstCategoryChange) {
          ignoreFirstCategoryChange = false;
          return;
        }

        checkTitle($scope.title ? $scope.title.text : null);
      });

      function checkTitle(title) {
        $scope.titleExists = false;

        if (!title || !$scope.category) {
          return;
        }

        api({
          url: '/works',
          params: {
            category: $scope.category,
            title: $scope.title.text
          }
        }).then(function(res) {
          $scope.titleExists = _.some(res.data, function(work) {
            return !$scope.titleWork.id || work.id != $scope.titleWork.id;
          });;
        });
      }
    },
    scope: {
      title: '=',
      titleIndex: '=',
      titleWork: '=',
      category: '=',
      deletable: '=',
      onRemove: '&'
    }
  };
});
