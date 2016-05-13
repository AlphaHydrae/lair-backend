angular.module('lair.api').service('api', function(apiPagination, apiRateLimit, $http, $log, urls) {

  var counter = 0;

  function service(options) {

    if (!options.url.match(/^https?:\/\//) && !options.url.match(/^\/\//) && !options.url.match(/^\/api\//)) {
      options.url = urls.join('/api', options.url);
    }

    // TODO: replace by $httpParamSerializerJQLike when upgrading to Angular 1.4
    if (options.params) {
      _.each(options.params, function(value, key) {
        if (_.isArray(value) && !key.match(/\[\]$/)) {
          options.params[key + '[]'] = value;
          delete options.params[key];
        }
      });
    }

    var n = ++counter;

    var logMessage = 'api ' + n + ' ' + (options.method || 'GET') + ' ' + options.url;
    logMessage += (options.params ? '?' + urls.queryString(options.params) : '');
    logMessage += (options.data ? ' ' + JSON.stringify(options.data) : '');
    $log.debug(logMessage);

    return $http(options).then(function(res) {
      res.n = n;
      res.rateLimit = apiRateLimit(res);
      res.pagination = apiPagination(res);
      return res;
    });
  }

  service.all = function(options) {

    var data = [];
    options.params = options.params || {};
    options.params.start = options.params.start || 0;
    options.params.number = options.params.number || 100;

    return service(options).then(function(res) {
      data = data.concat(res.data);
      if (res.pagination().hasMorePages() && options.start < 100 * options.number) {
        options.params.start += res.data.length;
        return service(options);
      } else {
        return data;
      }
    });
  };

  return service;
});
