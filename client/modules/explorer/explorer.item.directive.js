angular.module('lair.explorer').directive('explorerItem', function() {
  return {
    templateUrl: '/templates/modules/explorer/explorer.item.template.html',
    controller: 'ExplorerItemCtrl',
    scope: {
      item: '=',
      params: '='
    }
  };
});
