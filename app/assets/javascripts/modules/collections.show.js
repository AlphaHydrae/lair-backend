angular.module('lair.collections.show', [ 'lair.api', 'lair.explorer', 'lair.items.display' ])

  .controller('CollectionCtrl', function(api, explorer, $q, $scope, $stateParams) {

    fetchCollection();

    function fetchCollection() {
      api({
        url: '/collections',
        params: {
          userName: $stateParams.userName,
          name: $stateParams.collectionName
        }
      }).then(function(res) {
        if (res.data.length) {
          $scope.collection = res.data[0];
        } else {
          return $q.reject(new Error('No "' + $stateParams + '" collection found for user "' + $stateParams.userName + '"'));
        }
      });
    }
  })

;
