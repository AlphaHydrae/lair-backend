angular.module('lair.works.form').controller('WorkRelationshipCtrl', function(api, $log, $uibModal, $scope, works) {

  $scope.matchingPeople = [];
  $scope.matchingCompanies = [];

  $scope.fetchPeople = resourceFetcher('people');
  $scope.fetchCompanies = resourceFetcher('companies');

  $scope.$watchGroup([ 'relationship.personId', 'relationship.companyId' ], function(values) {
    if (values[0] !== undefined) {
      $scope.resource = 'people';
      loadRelations();
    } else if (values[1] !== undefined) {
      $scope.resource = 'companies';
      loadRelations();
    }
  });

  $scope.$watch('relationship.companyId', function(newValue) {
    if (newValue === -1) {
      createNewResource('companies');
    }
  });

  $scope.$watch('relationship.personId', function(newValue) {
    if (newValue === -1) {
      createNewResource('people');
    }
  });

  $scope.remove = function() {
    if ($scope.onRemove) {
      $scope.onRemove();
    }
  };

  function loadRelations() {

    var promise;
    if ($scope.resource == 'people') {
      promise = works.loadPersonRelations();
    } else if ($scope.resource == 'companies') {
      promise = works.loadCompanyRelations();
    }

    if (promise) {
      promise.then(function(relations) {
        $scope.relations = relations;
      });
    }
  }

  function createNewResource(resource) {

    var singularName = inflection.singularize(resource),
        controller = 'New' + inflection.capitalize(singularName) + 'Ctrl',
        templateUrl = '/templates/modules/works-form/form.new' + inflection.capitalize(singularName) + 'Dialog.template.html',
        matchingVar = 'matching' + inflection.capitalize(resource),
        idVar = singularName + 'Id';

    var modal = $uibModal.open({
      controller: controller,
      templateUrl: templateUrl,
      scope: $scope
    });

    modal.result.then(function(resource) {
      $scope[matchingVar].push(resource);
      $scope.relationship[idVar] = resource.id;
    }, function() {
      if ($scope.relationship[idVar] === -1) {
        $scope.relationship[idVar] = false;
      }
    });
  }

  function resourceFetcher(resource) {

    var association = inflection.singularize(resource),
        matchingVar = 'matching' + inflection.capitalize(resource);

    return function(search) {
      if (!search || !search.trim().length) {
        if ($scope.relationship[association]) {
          $scope[matchingVar] = _.compact([ $scope.relationship[association] ]);
        } else {
          $scope[matchingVar] = [];
        }

        return;
      }

      api({
        url: '/' + resource,
        params: {
          number: 100,
          search: search
        }
      }).then(function(res) {
        $scope[matchingVar] = res.data;
        $scope[matchingVar].unshift({ id: -1 });
      }, function(res) {
        $log.warn('Could not fetch ' + resource + ' matching "' + search + '"');
        $log.debug(res);
      });
    };
  }
});
