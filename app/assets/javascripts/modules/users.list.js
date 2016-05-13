angular.module('lair.users.list', [ 'lair.api', 'lair.tables' ])

  .controller('UsersListCtrl', function(api, $scope, tables) {

    tables.create($scope, 'usersList', {
      url: '/users'
    });
  })
;
