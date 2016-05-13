angular.module('lair.users', [ 'lair.api' ])

  .factory('users', function(api, $log) {

    var fetching,
        fetched = false;

    var service = {
      users: [],

      clearCache: function() {
        fetched = false;
      },

      fetchAllUsers: function(options) {
        options = options || {};

        if (fetching) {
          return fetching;
        } else if (fetched && !options.force) {
          return service.users;
        }

        fetching = api.all({
          url: '/users'
        });

        fetching.then(function(users) {
          fetched = true;
          service.users = users;
        }, function(res) {
          fetching = null;
          $log.warn('Could not fetch all users');
          $log.debug(res);
        });

        return fetching;
      },

      fetchUsersById: function(ids, options) {
        return service.fetchAllUsers(options).then(function(users) {
          return _.filter(users, function(user) {
            return _.contains(ids, user.id);
          });
        });
      }
    };

    return service;
  })

;
