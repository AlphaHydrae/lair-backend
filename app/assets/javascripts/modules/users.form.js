angular.module('lair.users.form', [ 'lair.forms' ])

  .controller('UserFormCtrl', function($scope) {
    $scope.roles = [ 'admin' ];
  })

;
