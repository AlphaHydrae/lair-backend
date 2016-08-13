angular.module('lair.works.form').controller('WorkFormCtrl', function(api, works, languages, $log, $uibModal, $q, $scope, $state, $stateParams) {

  $scope.workCategories = works.categories.slice();

  $scope.selectImage = function() {
    var modal = $uibModal.open({
      controller: 'SelectImageCtrl',
      templateUrl: '/templates/modules/images-select/select.template.html',
      scope: $scope,
      size: 'lg'
    });

    modal.result.then(function(image) {
      $scope.modifiedWork.image = image;
    });
  };

  languages.addLanguages($scope);

  $scope.searchForExistingTitle = function(text) {
    if (!$scope.modifiedWork) {
      return $q.when(false);
    }

    return api({
      url: '/works',
      params: {
        category: $scope.modifiedWork.category,
        title: text
      }
    }).then(function(res) {
      return _.some(res.data, function(work) {
        return !$scope.modifiedWork.id || work.id != $scope.modifiedWork.id;
      });
    });
  };

  $scope.workChanged = function() {
    return !angular.equals($scope.work, $scope.modifiedWork);
  };

  $scope.addLink = function() {
    $scope.modifiedWork.links.push({});
  };

  $scope.removeLink = function(link) {
    $scope.modifiedWork.links.splice($scope.modifiedWork.links.indexOf(link), 1);
  };

  $scope.addRelationship = function(type) {

    var relationship = {};
    if (type == 'person') {
      relationship.personId = false;
    } else if (type == 'company') {
      relationship.companyId = false;
    }

    $scope.modifiedWork.relationships.push(relationship);
  };

  $scope.removeRelationship = function(relationship) {
    $scope.modifiedWork.relationships.splice($scope.modifiedWork.relationships.indexOf(relationship), 1);
  };
});
