angular.module('lair.collections.list').controller('NewCollectionDialogCtrl', function(api, auth, $modalInstance, $scope) {

  $scope.collection = {
    restrictions: {
      ownerIds: [ auth.currentUser.id ]
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

  $scope.$watchGroup([ 'modifiedCollection.name', 'namePlaceholder' ], function(values) {

    var name = values[0],
        placeholder = values[1];

    $scope.namePlaceholderTaken = false;
    if (name && name.length) {
      return;
    } else if (!placeholder || !placeholder.length) {
      return;
    }

    api({
      url: '/collections',
      params: {
        userId: auth.currentUser.id,
        name: placeholder,
        number: 1
      }
    }).then(function(res) {
      $scope.namePlaceholderTaken = res.data.length;
    });
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
});
