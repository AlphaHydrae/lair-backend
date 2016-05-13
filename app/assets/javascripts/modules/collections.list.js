angular.module('lair.collections.list', [ 'lair.auth', 'lair.collections.preview', 'lair.infinite', 'ui.bootstrap.modal' ])

  .controller('CollectionsListCtrl', function(api, $modal, $q, $scope, $state, tables) {

    $scope.collectionsList = {
      records: [],
      httpSettings: {
        url: '/collections'
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
        templateUrl: '/templates/collections-new-dialog.html',
        controller: 'NewCollectionDialogCtrl',
        scope: $scope
      });

      modal.result.then(function(collection) {
        $state.go('collections.edit', {
          id: collection.id
        });
      });
    }
  })

  .controller('NewCollectionDialogCtrl', function(api, auth, $modalInstance, $scope) {

    $scope.collection = {
      restrictions: {
        owners: [ auth.currentUser.id ]
      }
    };

    $scope.modifiedCollection = angular.copy($scope.collection);

    $scope.save = createCollection;

    $scope.$watch('modifiedCollection.displayName', function(value) {
      value = value || '';

      $scope.namePlaceholder = value
        .replace(/[^a-z0-9\- ]+/gi, '')
        .replace(/ +/g, '-')
        .replace(/\-+/g, '-')
        .replace(/\-+$/, '')
        .replace(/^\-+/, '')
        .toLowerCase();
    });

    function createCollection() {

      var data = _.extend({}, $scope.modifiedCollection);
      if (!data.name || !data.name.trim().length) {
        data.name = $scope.namePlaceholder;
      }

      api({
        method: 'POST',
        url: '/collections',
        data: data
      }).then(function(res) {
        $modalInstance.close(res.data);
      });
    }
  })

;
