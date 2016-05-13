angular.module('lair.explorer').directive('explorerWork', function() {
  return {
    templateUrl: '/templates/modules/explorer/explorer.work.template.html',
    controller: 'ExplorerWorkCtrl',
    scope: {
      work: '=',
      params: '='
    }
  };
});
