angular.module('lair.api', [ 'lair.auth' ])

  .service('api', function($http, $log, urls) {

    var counter = 0;

    function RateLimit(total, remaining, reset) {
      this.total = total;
      this.remaining = remaining;
      this.reset = reset;
      this.resetIn = reset.getTime() - new Date().getTime();
    }

    RateLimit.prototype.isExceeded = function() {
      return this.remaining <= 0 && new Date() <= this.reset;
    };

    RateLimit.prototype.clear = function() {
      this.remaining = this.total;
    };

    function parsePaginationHeader(response, header, required) {

      var value = response.headers(header);
      if (!value) {
        if (required) {
          throw new Error('Exected response to have the ' + header + ' header');
        } else {
          return null;
        }
      }

      var number = parseInt(value, 10);
      if (isNaN(number)) {
        throw new Error('Expected response header ' + header + ' to contain an integer, got "' + value + '" (' + typeof(value) + ')');
      }

      return number;
    }

    function Pagination(response) {
      this.start = parsePaginationHeader(response, 'X-Pagination-Start', true);
      this.number = parsePaginationHeader(response, 'X-Pagination-Number', true);
      this.end = this.start + this.number;
      this.grandTotal = parsePaginationHeader(response, 'X-Pagination-Total', true);
      this.filteredTotal = parsePaginationHeader(response, 'X-Pagination-Filtered-Total', false);
      this.total = this.filteredTotal || this.filteredTotal === 0 ? this.filteredTotal : this.grandTotal;
      this.length = response.data.length;

      this.numberOfPages = Math.ceil(this.total / this.number);
    }

    Pagination.prototype.hasMorePages = function() {
      return this.total > this.start + this.number && this.length >= 1;
    };

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

        // enrich response with pagination function
        res.pagination = function() {

          if (!res._pagination) {
            // otherwise, parse the pagination data
            res._pagination = new Pagination(res);
            $log.debug('api ' + n + ' pagination: ' + JSON.stringify(res._pagination));
          }

          return res._pagination;
        };

        res.rateLimit = function() {

          var total = res.headers('X-RateLimit-Total'),
              remaining = res.headers('X-RateLimit-Remaining'),
              reset = res.headers('X-RateLimit-Reset');

          if (!total) {
            return null;
          }

          return new RateLimit(parseInt(total, 10), parseInt(remaining, 10), new Date(parseInt(reset, 10) * 1000));
        };

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
  })

  .factory('urls', function($window) {
    return {
      join: function() {

        var url = arguments[0],
            parts = Array.prototype.slice.call(arguments, 1);

        _.each(parts, function(part) {
          url += '/' + part.replace(/^\//, '');
        });

        return url;
      },

      queryString: function(params) {
        return $window.jQuery.param(params);
      }
    };
  })

;
