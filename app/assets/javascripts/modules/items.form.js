angular.module('lair.items.form', ['lair.forms', 'lair.images.select'])

  .controller('ItemFormCtrl', ['ApiService', '$log', '$modal', '$scope', '$state', '$stateParams', function($api, $log, $modal, $scope, $state, $stateParams) {

    $scope.relationshipPeople = [];

    $scope.$on('item', function() {
      $scope.relationshipPeople = [];
    });

    $scope.selectImage = function() {
      var modal = $modal.open({
        controller: 'SelectImageCtrl',
        templateUrl: '/templates/selectImageDialog.html',
        scope: $scope,
        size: 'lg'
      });

      modal.result.then(function(image) {
        $scope.modifiedItem.image = image;
      });
    };

    $scope.itemCategories = [ 'anime', 'book', 'manga', 'movie', 'show' ];
    $scope.relationshipRelations = [ 'author' ];

    $scope.titleSortOptions = {
      handle: '.move',
      cancel: '' // disable default jquery ui sortable behavior preventing elements of type ":input,button" to be used as handles
    };

    $api.http({
      url: '/api/languages'
    }).then(function(response) {
      $scope.languages = response.data;
    });

    $scope.relationshipPeople = [];

    $scope.fetchRelationshipPeople = function(relationship, index, search) {
      if (!search || !search.trim().length) {
        if ($scope.item.relationships[index]) {
          $scope.relationshipPeople[index] = _.compact([ $scope.item.relationships[index].person ]);
        } else {
          $scope.relationshipPeople[index] = [];
        }
        return;
      }

      $api.http({
        url: '/api/people',
        params: {
          pageSize: 100,
          search: search
        }
      }).then(function(res) {
        $scope.relationshipPeople[index] = res.data;
      }, function(res) {
        $log.warn('Could not fetch items matching "' + search + '"');
        $log.debug(res);
      });
    };

    $scope.itemChanged = function() {
      return !angular.equals($scope.item, $scope.modifiedItem);
    };

    $scope.addTitle = function() {
      $scope.modifiedItem.titles.push({});
    };

    $scope.removeTitle = function(title) {
      $scope.modifiedItem.titles.splice($scope.modifiedItem.titles.indexOf(title), 1);
    };

    $scope.addLink = function() {
      $scope.modifiedItem.links.push({});
    };

    $scope.removeLink = function(link) {
      $scope.modifiedItem.links.splice($scope.modifiedItem.links.indexOf(link), 1);
    };

    $scope.addRelationship = function() {
      $scope.modifiedItem.relationships.push({ relation: 'author' });
      $scope.relationshipPeople.push([]);
    };

    $scope.removeRelationship = function(relationship) {
      $scope.modifiedItem.relationships.splice($scope.modifiedItem.relationships.indexOf(relationship), 1);
    };

    $scope.addTag = function() {
      $scope.modifiedItem.tags.push({});
    };

    $scope.removeTag = function(tag) {
      $scope.modifiedItem.tags.splice($scope.modifiedItem.tags.indexOf(tag), 1);
    };
  }])

;
