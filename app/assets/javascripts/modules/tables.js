angular.module('lair.tables', [])

  .factory('tables', function(api) {

    var service = {
      create: function($scope, name, options) {

        var list = $scope[name] = {
          initialized: false,
          records: []
        };

        list.refresh = function(table) {

          table.pagination.start = table.pagination.start || 0;
          table.pagination.number = table.pagination.number || options.pageSize || 15;

          var params = _.extend({}, options.params, {
            start: table.pagination.start,
            number: table.pagination.number
          });

          $scope.$broadcast(name + '.refresh');

          api({
            url: options.url,
            params: params
          }).then(updatePagination).then(updateRecords);

          function updatePagination(res) {
            table.pagination.numberOfPages = res.pagination().numberOfPages;
            return res;
          }

          function updateRecords(res) {
            list.records = res.data;
            $scope.$broadcast(name + '.refreshed', list, table);
            list.initialized = true;
          }
        };

        return list;
      }
    };

    return service;
  })

  .directive('stDeleteRecord', function($log) {
    return {
    restrict: 'AE',
      require: '^stTable',
      scope: {
        callback: '&'
      },
      link: function(scope, element, attrs, ctrl) {

        var table = ctrl.tableState();

        element.on('click', function(ev) {
          scope.callback.call().then(function(result) {
            if (result) {
              $log.debug('Refresh table due to deleted record');
              ctrl.pipe();
            }
          });
        });
      }
    };
  })

  .controller('PaginationCtrl', function($scope) {

    $scope.directPageLinks = [];

    $scope.$watchGroup([ 'currentPage', 'numPages' ], function(values) {

      var currentPage = values[0],
          numPages = values[1];

      if (currentPage === undefined || numPages === undefined) {
        $scope.directPageLinks = [];
        return;
      }

      if (numPages <= 7 || currentPage <= 4) {
        $scope.directPageLinks = _.times(numPages < 7 ? numPages : 7, function(i) {
          return i + 1;
        });
      } else if (currentPage + 3 > numPages) {
        $scope.directPageLinks = _.times(7, function(i) {
          return numPages - 6 + i;
        });
      } else {
        $scope.directPageLinks = _.times(7, function(i) {
          return currentPage - 3 + i;
        });
      }
    });

  })

;
