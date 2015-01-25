angular.module('lair.items.edit', ['ui.sortable'])

  .controller('EditItemController', ['ApiService', '$scope', '$stateParams', function($api, $scope, $stateParams) {

    $scope.titleSortOptions = {
      handle: '.move',
      cancel: '' // disable default jquery ui sortable behavior preventing elements of type ":input,button" to be used as handles
    };

    $api.http({
      url: '/api/items/' + $stateParams.itemId
    }).then(function(response) {
      $scope.item = response.data;
    });
  }])

;
