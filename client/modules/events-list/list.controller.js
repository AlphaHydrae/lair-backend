angular.module('lair.events.list').controller('EventsListCtrl', function(api, $log, moment, $q, $scope) {

  var resourceEventTypes = [ 'create', 'update', 'delete' ];

  $scope.eventFilters = {
    resource: ''
  };

  $scope.ownershipItems = [];

  $scope.$watch('events', function(events) {
    if (!events) {
      return;
    }

    var ownerships = _.where(events, { resource: 'ownerships' });

    $q.all(_.map(ownerships, function(ownership) {

      var version = ownership.eventVersion;
      if (ownership.type == 'delete') {
        version = ownership.previousVersion;
      }

      return api({
        url: '/items/' + version.itemId
      }).then(function(res) {
        return res.data;
      });
    })).then(function(items) {
      $scope.ownershipItems = items;
    });
  });

  $scope.description = function(event) {
    if (_.contains(resourceEventTypes, event.type)) {

      var version = event.eventVersion;
      if (event.type == 'delete') {
        version = event.previousVersion;
      }

      if (event.resource == 'collections') {
        return version.name;
      } else if (event.resource == 'works') {
        return version.titles[0].text;
      } else if (event.resource == 'items') {
        return version.title.text;
      } else if (event.resource == 'companies') {
        return version.name;
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
        var item = _.findWhere($scope.ownershipItems, { id: version.itemId });
        return item ? item.title.text + ' gotten at ' + moment(version.gottenAt).format('LL') : '-';
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

    var params = {
      start: table.pagination.start,
      number: table.pagination.number,
      withUser: 1
    };

    if ($scope.eventFilters.resource && $scope.eventFilters.resource.length) {
      params.resource = $scope.eventFilters.resource;
    }

    api({
      url: '/events',
      params: params
    }).then(function(res) {
      $scope.events = res.data;
      table.pagination.numberOfPages = res.pagination().numberOfPages;
    }, function(err) {
      $log.warn('Could not fetch ownerships');
      $log.debug(err);
    });
  };
});
