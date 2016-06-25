angular.module('lair.mediaIdent.dialog').factory('mediaIdentDialog', function($modal) {

  var service = {
    open: function($scope, options) {
      options = _.extend({}, options);

      var scope = $scope.$new();
      _.extend(scope, _.pick(options, 'mediaDirectory'));

      var modal = $modal.open({
        size: 'lg',
        scope: scope,
        controller: 'MediaIdentDialogCtrl',
        templateUrl: '/templates/modules/media-ident-dialog/dialog.template.html'
      });

      return modal.result;
    }
  };

  return service;
});
