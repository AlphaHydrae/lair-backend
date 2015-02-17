angular.module('lair.people', [])

  .directive('personName', function() {
    return {
      restrict: 'E',
      scope: {
        person: '='
      },
      controller: ['$scope', function($scope) {
        $scope.buildName = function(person) {
          if (!person) {
            return '-';
          }

          var parts = [];

          if (person.lastName) {
            parts.push(person.lastName.toUpperCase());
          }

          if (person.firstNames) {
            parts.push(person.firstNames);
          }

          if (person.pseudonym) {
            parts.push(parts.length ? '(' + person.pseudonym + ')' : person.pseudonym);
          }

          return parts.join(' ');
        };
      }],
      template: '{{ buildName(person) }}'
    };
  })
;
