angular.module('lair.infinite', [ 'infinite-scroll', 'lair.api', 'lair.auth' ])

  .run(function() {
    angular.module('infinite-scroll').value('THROTTLE_MILLISECONDS', 1000);
  })

;
