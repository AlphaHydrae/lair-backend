angular.module('lair.events', [ 'lair.tables' ])

  .controller('EventListCtrl', ['ApiService', '$log', 'moment', '$q', '$scope', function($api, $log, moment, $q, $scope) {

    var resourceEventTypes = [ 'create', 'update', 'delete' ];

    $scope.eventFilters = {
      resource: ''
    };

    $scope.ownershipItemParts = [];

    $scope.$watch('events', function(events) {
      if (!events) {
        return;
      }

      var ownerships = _.where(events, { resource: 'ownerships' });

      $q.all(_.map(ownerships, function(ownership) {
        return $api.http({
          url: '/api/parts/' + ownership.eventVersion.partId
        }).then(function(res) {
          return res.data;
        });
      })).then(function(parts) {
        $scope.ownershipItemParts = parts;
      });
    });

    $scope.description = function(event) {
      if (_.contains(resourceEventTypes, event.type)) {

        var version = event.eventVersion;
        if (event.type == 'delete') {
          version = event.previousVersion;
        }

        if (event.resource == 'items') {
          return version.titles[0].text;
        } else if (event.resource == 'item-parts') {
          return version.title.text;
        } else if (event.resource == 'people') {

          var person = version,
              parts = [];

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
        } else if (event.resource == 'ownerships') {
          var part = _.findWhere($scope.ownershipItemParts, { id: version.partId });
          return part ? part.title.text + ' gotten at ' + moment(version.gottenAt).format('LL') : '-';
        } else if (event.resource == 'image-searches') {
          return 'Search for "' + version.query + '" with ' + version.engine;
        } else {
          return '-';
        }
      } else {
        return '-';
      }
    };

    $scope.fetchEvents = function(table) {

      table.pagination.start = table.pagination.start || 0;
      table.pagination.number = table.pagination.number || 15;

      var pageSize = table.pagination.number,
          page = table.pagination.start / pageSize + 1,
          params = {
            page: page,
            pageSize: pageSize
          };

      if ($scope.eventFilters.resource && $scope.eventFilters.resource.length) {
        params.resource = $scope.eventFilters.resource;
      }

      $api.http({
        url: '/api/events',
        params: params
      }).then(function(res) {
        $scope.events = res.data;
        table.pagination.numberOfPages = res.pagination().numberOfPages;
      }, function(err) {
        $log.warn('Could not fetch ownerships');
        $log.debug(err);
      });
    };
  }])

  .directive('filterEvents', function() {
    return {
      restrict: 'E',
      require: '^stTable',
      templateUrl: '/templates/filterEvents.html',
      scope: {
        filters: '='
      },
      link: function($scope, element, attr, ctrl) {

        var lastValue;

        $scope.eventResources = [ '', 'image-searches', 'item-parts', 'items', 'ownerships', 'people' ];

        $scope.$watch('filters', function(value) {
          if (value) {
            if (lastValue) {

              var table = ctrl.tableState();
              table.pagination.start = 0;

              ctrl.pipe();
            } else {
              lastValue = value;
            }
          }
        }, true);
      }
    };
  })

;
