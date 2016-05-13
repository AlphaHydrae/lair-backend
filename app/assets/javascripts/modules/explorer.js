angular.module('lair.explorer', [ 'lair.explorer.item', 'lair.explorer.part' ])

  .factory('explorer', function($modal, $rootScope) {

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
            templateUrl: '/templates/explorer-dialog.html',
            controller: 'ExplorerCtrl',
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
  })

  .controller('ExplorerCtrl', function(api, $scope) {
  })

;
