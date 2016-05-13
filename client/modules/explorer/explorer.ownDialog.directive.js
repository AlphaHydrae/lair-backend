angular.module('lair.explorer').directive('ownDialog', function ($compile) {
  return function(scope, element, attrs) {

    var shown = false,
        contentTemplate = _.template('<form ng-controller="OwnDialogCtrl" ng-submit="create()" class="ownDialog"><div class="form-group"><label>Owned since</label><input class="form-control" ui-date="dateOptions" ng-model="ownership.gottenAt" /></div><button type="submit" class="btn btn-primary btn-block">Add</button></form>');

    element.on('mouseenter', function() {
      if (!shown) {
        element.tooltip('show');
      }
    });

    element.on('mouseleave', function() {
      element.tooltip('hide');
    });

    scope.$on('ownership', function() {
      element.popover('hide');
      shown = false;
    });

    element.on('click', function() {
      element.popover(shown ? 'hide' : 'show');
      element.tooltip(shown ? 'show' : 'hide');
      shown = !shown;
    });

    element.tooltip({
      trigger: 'manual',
      title: 'I own this'
    });

    element.popover({
      trigger: 'manual',
      placement: 'auto',
      content: $compile(contentTemplate({}))(scope),
      html: true,
      template: '<div class="popover ownDialogPopover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>'
    });
  };
});
