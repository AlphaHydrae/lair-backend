angular.module('lair.works.form').controller('WorkFormCtrl', function(api, works, $log, $modal, $scope, $state, $stateParams) {

  $scope.relations = works.relations;

  $scope.workCategories = works.categories.slice();

  $scope.$watch('modifiedWork.category', function(value) {
    if (value) {
      $scope.relations = works.relationsForWork($scope.modifiedWork);
      $scope.modifiedWork.relationships = _.filter($scope.modifiedWork.relationships, function(relationship) {
        return !!_.findWhere($scope.relations, { name: relationship.relation });
      });
    }
  });

  $scope.selectImage = function() {
    var modal = $modal.open({
      controller: 'SelectImageCtrl',
      templateUrl: '/templates/modules/images-select/select.template.html',
      scope: $scope,
      size: 'lg'
    });

    modal.result.then(function(image) {
      $scope.modifiedWork.image = image;
    });
  };

  $scope.titleSortOptions = {
    handle: '.move',
    cancel: '' // disable default jquery ui sortable behavior preventing elements of type ":input,button" to be used as handles
  };

  api({
    url: '/languages'
  }).then(function(response) {
    $scope.languages = response.data;
  });

  $scope.workChanged = function() {
    return !angular.equals($scope.work, $scope.modifiedWork);
  };

  $scope.addTitle = function() {
    $scope.modifiedWork.titles.push({});
  };

  $scope.removeTitle = function(title) {
    $scope.modifiedWork.titles.splice($scope.modifiedWork.titles.indexOf(title), 1);
  };

  $scope.addLink = function() {
    $scope.modifiedWork.links.push({});
  };

  $scope.removeLink = function(link) {
    $scope.modifiedWork.links.splice($scope.modifiedWork.links.indexOf(link), 1);
  };

  $scope.addRelationship = function(relation) {
    $scope.modifiedWork.relationships.push({ relation: relation.name });
  };

  $scope.removeRelationship = function(relationship) {
    $scope.modifiedWork.relationships.splice($scope.modifiedWork.relationships.indexOf(relationship), 1);
  };
});
