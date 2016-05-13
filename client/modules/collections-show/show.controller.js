angular.module('lair.collections.show').controller('CollectionCtrl', function(api, explorer, $q, $scope, $stateParams) {

  fetchCollection();

  function fetchCollection() {
    api({
      url: '/collections',
      params: {
        userName: $stateParams.userName,
        name: $stateParams.collectionName,
        withUser: 1
      }
    }).then(function(res) {
      if (res.data.length) {
        $scope.collection = res.data[0];
        fetchCollectionResourceCount('works');
        fetchCollectionResourceCount('items');
      } else {
        return $q.reject(new Error('No "' + $stateParams + '" collection found for user "' + $stateParams.userName + '"'));
      }
    });
  }

  function fetchCollectionResourceCount(resource) {
    api({
      url: '/' + resource,
      params: {
        number: 1,
        collectionId: $scope.collection.id
      }
    }).then(function(res) {
      $scope['total' + inflection.capitalize(resource)] = res.pagination().total;
    });
  }
});
