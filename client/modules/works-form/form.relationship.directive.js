angular.module('lair.works.form').directive('workRelationship', function() {
  return {
    restrict: 'E',
    controller: 'WorkRelationshipCtrl',
    templateUrl: '/templates/modules/works-form/form.relationship.template.html',
    scope: {
      relationship: '=',
      onRemove: '&'
    }
  };
});
