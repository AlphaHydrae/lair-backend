angular.module('lair.collections.list').controller('CollectionsListCtrl', function(api, explorer, $uibModal, $q, $scope, $state, tables) {

  explorer.openFromLocation($scope);

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

    var modal = $uibModal.open({
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
