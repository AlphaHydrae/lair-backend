angular.module('lair.forms', [])

  .factory('forms', function() {

    var service = {
      dataEquals: function(data1, data2) {
        if (_.isArray(data1) && _.isArray(data2)) {
          return data1.length == data2.length && _.every(data1, function(e, i) {
            return service.dataEquals(e, data2[i]);
          });
        } else if (_.isObject(data1) && _.isObject(data2)) {

          var keys = _.union(_.keys(data1), _.keys(data2));

          var ignore = Array.prototype.slice.call(arguments, 2);
          keys = _.without.apply(_, [ keys ].concat(ignore));

          return _.every(keys, function(key) {
            return service.dataEquals(data1[key], data2[key]);
          });
        } else if (data1 === undefined && data2 === undefined) {
          return true;
        } else if ((_.isArray(data1) && data1.length == 1) != (_.isArray(data2) && data2.length == 1)) {
          return false;
        } else {
          return (data1 || false) == (data2 || false);
        }
      }
    };

    return service;
  })

  .directive('ngIndeterminate', function() {
    return {
      restrict: 'A',
      link: function(scope, element, attributes) {
        scope.$watch(attributes.ngIndeterminate, function(value) {
          element.prop('indeterminate', !!value);
        });
      }
    };
  })

  .directive('languageSelect', function() {
    return {
      restrict: 'E',
      scope: {
        languages: '=',
        model: '=ngModel'
      },
      templateUrl: '/templates/selectLanguage.html',
      controller: function($scope) {

        $scope.updateSelection = function(language) {
          $scope.model = language.tag;
        };

        $scope.groupCommonLanguages = function(language) {
          return language.used ? 'Common' : 'Other';
        };
      }
    };
  })
;
