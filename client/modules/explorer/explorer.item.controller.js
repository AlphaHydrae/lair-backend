angular.module('lair.explorer').controller('ExplorerItemCtrl', function(api, auth, explorer, $log, $scope, $state) {

  $scope.currentUser = auth.currentUser;
  auth.addAuthFunctions($scope);

  $scope.edit = function(item) {
    explorer.close();
    $state.go('items.edit', {
      itemId: item.id
    });
  };

  $scope.showWork = function() {
    api({
      url: '/works/' + $scope.item.workId
    }).then(function(res) {
      explorer.open('works', res.data);
    });
  };

  $scope.formatIsbn = function(isbn) {
    return isbn ? ISBN.hyphenate(isbn) : '-';
  };

  $scope.$on('ownership', function(event, ownership, item) {
    // FIXME: move this to OwnDialogCtrl
    api({
      method: 'POST',
      url: '/ownerships',
      data: ownership
    }).then(function() {
      item.ownedByMe = true;
    }, function(err) {
      $log.warn('Could not create ownership for item ' + item.id);
      $log.debug(err);
    });
  });
});
