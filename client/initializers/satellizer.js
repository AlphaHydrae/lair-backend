angular.module('lair').config(function($authProvider) {
  $authProvider.tokenPrefix = 'lair.satellizer';
});
