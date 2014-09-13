describe("lair.auth", function() {
  beforeEach(module("lair.auth"));

  var $q,
      $rootScope;

  describe("when run", function() {

    var authServiceMock;

    beforeEach(function() {

      authServiceMock = {
        checkAuthentication: function() {}
      };

      spyOn(authServiceMock, 'checkAuthentication');

      module(function($provide) {
        $provide.value('AuthService', authServiceMock);
      });

      // trigger the injection
      inject(function($injector) {});
    });

    it("should check authentication", function() {
      expect(authServiceMock.checkAuthentication).toHaveBeenCalled();
    });
  });

  describe("AuthService", function() {

    var mocks,
        service;

    beforeEach(function() {
      module(function($provide) {
        $provide.value('config.googleOAuth2ClientId', 'foo');
        $provide.value('config.googleOAuth2CallbackUrl', 'bar');
      });
    });

    describe("#start", function() {

      var testResponse;

      beforeEach(function() {

        mocks = {
          http: function() {},
          localStorage: {
            get: function() {}
          }
        };

        spyOn(mocks, 'http').andCallFake(function() {
          return testResponse instanceof Error ? $q.reject(testResponse) : $q.when(testResponse);
        });

        module(function($provide) {
          $provide.value('$http', mocks.http);
          $provide.value('localStorageService', mocks.localStorage);
        });

        inject(function($injector, _$q_, _$rootScope_) {
          $q = _$q_;
          $rootScope = _$rootScope_;
          service = $injector.get('AuthService');
        });
      });

      it("should generate a csrf token once and return a fulfilled promise", function() {

        testResponse = {};
        spyOn(mocks.localStorage, 'get').andReturn(null);

        var fulfilledSpy = jasmine.createSpy();
        service.start().then(fulfilledSpy);

        $rootScope.$apply();

        expect(mocks.localStorage.get).toHaveBeenCalledWith('auth.strategy');
        expect(mocks.http).toHaveBeenCalledWith({
          method: 'POST',
          url: '/users/auth/start'
        });
        expect(fulfilledSpy).toHaveBeenCalledWith(null);

        fulfilledSpy = jasmine.createSpy();
        service.start().then(fulfilledSpy);

        $rootScope.$apply();

        expect(mocks.localStorage.get.calls.length).toBe(2);
        expect(mocks.localStorage.get.calls[1].args).toEqual(['auth.strategy']);
        expect(mocks.http.calls.length).toBe(1);
        expect(fulfilledSpy).toHaveBeenCalledWith(null);
      });

      it("should fulfill the promise with the previously used authentication strategy if available", function() {

        testResponse = {};
        spyOn(mocks.localStorage, 'get').andReturn('foo');

        var fulfilledSpy = jasmine.createSpy();
        service.start().then(fulfilledSpy);

        $rootScope.$apply();

        expect(fulfilledSpy).toHaveBeenCalledWith('foo');

        fulfilledSpy = jasmine.createSpy();
        service.start().then(fulfilledSpy);

        $rootScope.$apply();

        expect(fulfilledSpy).toHaveBeenCalledWith('foo');
      });

      it("should return a rejected promise if the token generation fails", function() {

        testResponse = new Error('bug');
        spyOn(mocks.localStorage, 'get').andReturn(null);

        var rejectedSpy = jasmine.createSpy();
        service.start().then(undefined, rejectedSpy);

        $rootScope.$apply();

        expect(rejectedSpy).toHaveBeenCalled();
        expect(rejectedSpy.calls[0].args[0]).toBeError('The authentication service is unavailable. Please try again later.');

        rejectedSpy = jasmine.createSpy();
        service.start().then(undefined, rejectedSpy);

        $rootScope.$apply();

        expect(rejectedSpy).toHaveBeenCalled();
        expect(rejectedSpy.calls[0].args[0]).toBeError('The authentication service is unavailable. Please try again later.');
      });
    });

    describe("#checkAuthentication", function() {

      beforeEach(function() {

        mocks = {
          localStorage: {
            get: function() {}
          }
        };

        module(function($provide) {
          $provide.value('localStorageService', mocks.localStorage);
        });

        inject(function($injector) {
          service = $injector.get('AuthService');
          spyOn(service, 'setAuthentication');
        });
      });

      it("should call #setAuthentication if an authentication payload is stored", function() {
        var payload = { foo: 'bar' };
        spyOn(mocks.localStorage, 'get').andReturn(payload);
        service.checkAuthentication();
        expect(service.setAuthentication).toHaveBeenCalledWith({ payload: payload });
      });

      it("should not do anything if no authentication payload is stored", function() {
        spyOn(mocks.localStorage, 'get').andReturn(null);
        service.checkAuthentication();
        expect(service.setAuthentication).not.toHaveBeenCalled();
      });
    });
  });
});
