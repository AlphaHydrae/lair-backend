angular.module('lair.items.edit', [])

  .controller('EditItemController', ['ApiService', '$scope', '$stateParams', function($api, $scope, $stateParams) {

    $api.http({
      url: '/api/items/' + $stateParams.itemId
    }).then(function(response) {
      $scope.item = response.data;
    });

    $scope.saveTitle = function(title) {
      $scope.titleChanged = true;
      $scope.titleSaved = false;
      $api.http({
        method: 'PATCH',
        url: '/api/items/' + $scope.item.key + '/titles/' + title.key,
        params: {
          text: title.text
        }
      }).then(function(response) {
        $scope.titleChanged = false;
        $scope.titleSaved = true;
      });
    };
  }])

;
