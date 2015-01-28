angular.module('lair.items.edit', ['ui.sortable'])

  .controller('EditItemController', ['ApiService', '$scope', '$stateParams', function($api, $scope, $stateParams) {

    $scope.itemCategories = [ 'anime', 'manga', 'movie', 'show' ];

    $scope.titleSortOptions = {
      handle: '.move',
      cancel: '' // disable default jquery ui sortable behavior preventing elements of type ":input,button" to be used as handles
    };

    $api.http({
      url: '/api/items/' + $stateParams.itemId
    }).then(function(response) {
      $scope.item = response.data;
      $scope.reset();
    });

    $api.http({
      url: '/api/languages'
    }).then(function(response) {
      $scope.languages = response.data;
    });

    $scope.save = function() {
      $api.http({
        method: 'PATCH',
        url: '/api/items/' + $stateParams.itemId,
        data: $scope.editedItem
      }).then(function(response) {
        $scope.item = response.data;
        $scope.reset();
      }, function(response) {
        // TODO: handle error
        console.log('FAILED!');
        console.log(response);
      });
    };

    $scope.reset = function() {
      $scope.editedItem = angular.copy($scope.item);
    };

    $scope.itemChanged = function() {
      return !angular.equals($scope.item, $scope.editedItem);
    };

    $scope.addTitle = function() {
      $scope.editedItem.titles.push({});
    };

    $scope.removeTitle = function(title) {
      $scope.editedItem.titles.splice($scope.editedItem.titles.indexOf(title), 1);
    };

    $scope.addLink = function() {
      $scope.editedItem.links.push({});
    };

    $scope.removeLink = function(link) {
      $scope.editedItem.links.splice($scope.editedItem.links.indexOf(link), 1);
    };
  }])

;
