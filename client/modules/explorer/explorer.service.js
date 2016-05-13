angular.module('lair.explorer').factory('explorer', function($modal, $rootScope) {

  var modal,
      scope;

  var service = {
    open: function(resourceType, resource, options) {
      options = options || {};

      if (!scope) {
        scope = $rootScope.$new();
      }

      scope.resourceType = resourceType;
      scope.resource = resource;

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

      return closed;
    }
  };

  return service;
});
