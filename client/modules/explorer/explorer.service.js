angular.module('lair.explorer').factory('explorer', function(api, $location, $log, $modal, $rootScope) {

  var modal,
      scope;

  var service = {
    openFromLocation: function($scope) {

      $scope.$on('$locationChangeSuccess', function(event, search, oldSearch) {
        openFromLocation();
      });

      openFromLocation();
    },

    open: function(resourceType, resource, options) {
      options = _.extend({}, options);

      if (!scope) {
        scope = $rootScope.$new();
      }

      scope.resourceType = resourceType;
      scope.resource = resource;

      $location.search('explore', inflection.singularize(resourceType) + '-' + resource.id);

      if (options.params) {
        scope.params = options.params;
      }

      if (!modal) {
        modal = $modal.open({
          templateUrl: '/templates/modules/explorer/explorer.template.html',
          scope: scope,
          size: 'lg'
        });
      }

      modal.result.then(service.close, service.close);

      return modal.result;
    },

    close: function(result) {

      var closed;
      if (modal) {
        closed = modal.close(result);
      }

      modal = null;
      scope = null;

      $location.search('explore', null);

      return closed;
    }
  };

  function openFromLocation() {

    var search = $location.search();
    if (!search.explore) {
      return service.close();
    }

    var exploreParts = search.explore.split('-');
    if (exploreParts.length != 2) {
      return service.close();
    }

    var resourceType = inflection.pluralize(exploreParts[0]),
        resourceId = exploreParts[1];

    if (resourceType != 'works' && resourceType != 'items') {
      $log.warn('Unsupported resource type "' + resourceType + '"');
      return service.close();
    }

    api({
      url: '/' + resourceType + '/' + resourceId
    }).then(function(res) {
      service.open(resourceType, res.data);
    });
  }

  return service;
});
