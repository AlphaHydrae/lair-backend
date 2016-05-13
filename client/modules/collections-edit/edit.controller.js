angular.module('lair.collections.edit').controller('EditCollectionCtrl', function(api, $scope, $state, $stateParams, users) {

  $scope.save = _.partial(updateCollection, false);
  $scope.saveAndMakePublic = _.partial(updateCollection, true);
  $scope.delete = deleteCollection;
  $scope.reset = resetModifiedCollection;

  $scope.tabs = {
    restrictions: true,
    defaultFilters: false,
    manualSelection: false
  };

  $scope.$watch('collection', resetModifiedCollection);

  $scope.$watch('modifiedCollection.public', function(value) {
    if (value === false) {
      $scope.modifiedCollection.featured = false;
    }
  });

  api({
    url: '/collections/' + $stateParams.id,
    params: {
      withUser: 1
    }
  }).then(function(res) {
    $scope.collection = res.data;
  });

  users.fetchAllUsers().then(function(users) {
    $scope.allUsers = users;
  });

  function updateCollection(makePublic) {

    var data = _.extend({}, $scope.modifiedCollection);

    if (makePublic) {
      data.public = true;
    }

    api({
      method: 'PATCH',
      url: '/collections/' + $stateParams.id,
      data: data,
      params: {
        withUser: 1
      }
    }).then(function(res) {
      $scope.collection = res.data;
    });
  }

  function deleteCollection(collection) {
    if (!confirm('Are you sure you want to delete "' + $scope.collection.displayName + '"?')) {
      return;
    }

    api({
      method: 'DELETE',
      url: '/collections/' + $scope.collection.id
    }).then(function() {
      $state.go('collections.list');
    });
  }

  function resetModifiedCollection() {
    $scope.modifiedCollection = angular.copy($scope.collection);
  }
});
