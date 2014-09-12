describe("lair.auth.strategy.test", function() {
  beforeEach(module('lair.auth.strategy.test'));

  describe("TestAuthService", function() {

    var mocks,
        $q,
        $rootScope,
        service,
        testResponse;

    beforeEach(function() {

      mocks = {
        http: function() {}
      };

      spyOn(mocks, 'http').andCallFake(function() {
        return testResponse instanceof Error ? $q.reject(testResponse) : $q.when(testResponse);
      });

      module(function($provide) {
        $provide.value('$http', mocks.http);
      });

      inject(function($injector, _$q_, _$rootScope_) {
        $q = _$q_;
        $rootScope = _$rootScope_;
        service = $injector.get('TestAuthService');
      });
    });

    it("should expose a signIn function", function() {
      expect(_.keys(service)).toEqual(['signIn']);
    });

    describe("#signIn", function() {

      function expectApiAuthCall(token) {
        expect(mocks.http).toHaveBeenCalledWith({
          method: 'GET',
          url: '/api/auth',
          headers: {
            Authorization: 'Bearer ' + token
          }
        });
      }

      it("should validate the given token by calling /api/auth and return the response data", function() {

        var data = { foo: 'bar' };
        testResponse = { data: data };

        var fulfilledSpy = jasmine.createSpy();
        service.signIn('baz').then(fulfilledSpy);

        $rootScope.$apply();

        expectApiAuthCall('baz');
        expect(fulfilledSpy).toHaveBeenCalledWith(data);
      });

      it("should return a rejected promise if an error occurs", function() {

        var error = new Error('bug');
        testResponse = error;

        var rejectedSpy = jasmine.createSpy();
        service.signIn('qux').then(undefined, rejectedSpy);

        $rootScope.$apply();

        expectApiAuthCall('qux');
        expect(rejectedSpy).toHaveBeenCalledWith(error);
      });
    });
  });
});
