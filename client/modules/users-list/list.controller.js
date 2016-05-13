angular.module('lair.users.list').controller('UsersListCtrl', function(api, $scope, tables) {
  tables.create($scope, 'usersList', {
    url: '/users'
  });
});
