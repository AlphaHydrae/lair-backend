angular.module('lair.collections.list').controller('CollectionsListCtrl', function(api, $modal, $q, $scope, $state, tables) {

  $scope.collectionsList = {
    records: [],
    httpSettings: {
      url: '/collections',
      params: {
        withUser: 1
      }
    },
    options: {
      enabled: true
    }
  };

  $scope.new = openNewCollectionDialog;

  $scope.updateCount = function(res) {
    $scope.collectionsCount = res.pagination().total;
  };

  function openNewCollectionDialog() {

    var modal = $modal.open({
      templateUrl: '/templates/modules/collections-list/list.newDialog.template.html',
      controller: 'NewCollectionDialogCtrl',
      scope: $scope
    });

    modal.result.then(function(collection) {
      $state.go('collections.edit', {
        id: collection.id
      });
    });
  }
});
