describe("lair.auth.strategy", function() {
  beforeEach(module('lair.auth.strategy'));

  describe("AuthStrategiesService", function() {

    var service,
        googleAuthMock,
        testAuthMock,
        $q,
        $rootScope;

    beforeEach(function() {

      googleAuthMock = {
        checkSignedIn: function() {},
        signIn: function() {}
      };

      testAuthMock = {
        signIn: function() {}
      };

      module(function($provide) {
        $provide.value('GoogleAuthService', googleAuthMock);
        $provide.value('TestAuthService', testAuthMock);
      });

      inject(function($injector, _$q_, _$rootScope_) {
        $q = _$q_;
        $rootScope = _$rootScope_;
        service = $injector.get('AuthStrategiesService');
      });
    });

    describe("#checkSignedIn", function() {

      beforeEach(function() {
        spyOn(googleAuthMock, 'signIn');
        spyOn(testAuthMock, 'signIn');
      });

      function expectNoCallsToSignIn() {
        expect(googleAuthMock.signIn).not.toHaveBeenCalled();
        expect(testAuthMock.signIn).not.toHaveBeenCalled();
      }

      it("should call #checkSignedIn on the chosen strategy", function() {

        spyOn(googleAuthMock, 'checkSignedIn').andReturn($q.when('foo'));

        var fulfilledSpy = jasmine.createSpy();
        service.checkSignedIn({ strategyName: 'google' }).then(fulfilledSpy);

        $rootScope.$apply();

        expectNoCallsToSignIn();
        expect(googleAuthMock.checkSignedIn).toHaveBeenCalledWith();
        expect(fulfilledSpy).toHaveBeenCalledWith('foo');
      });

      it("should return a rejected promise if the check fails", function() {

        var error = new Error('bug');
        spyOn(googleAuthMock, 'checkSignedIn').andReturn($q.reject(error));

        var rejectedSpy = jasmine.createSpy();
        service.checkSignedIn({ strategyName: 'google' }).then(undefined, rejectedSpy);

        $rootScope.$apply();

        expectNoCallsToSignIn();
        expect(googleAuthMock.checkSignedIn).toHaveBeenCalledWith();
        expect(rejectedSpy).toHaveBeenCalledWith(error);
      });

      it("should return a rejected promise for an unknown strategy", function() {

        spyOn(googleAuthMock, 'checkSignedIn');

        var rejectedSpy = jasmine.createSpy();
        service.checkSignedIn({ strategyName: 'unknown' }).then(undefined, rejectedSpy);

        $rootScope.$apply();

        expectNoCallsToSignIn();
        expect(googleAuthMock.checkSignedIn).not.toHaveBeenCalled();
        expect(rejectedSpy).toHaveBeenCalledWith(new Error('Unknown authentication strategy unknown'));
      });

      it("should return a rejected promise if the strategy does not have a #checkSignedIn function", function() {

        spyOn(googleAuthMock, 'checkSignedIn');

        var rejectedSpy = jasmine.createSpy();
        service.checkSignedIn({ strategyName: 'test' }).then(undefined, rejectedSpy);

        $rootScope.$apply();

        expectNoCallsToSignIn();
        expect(googleAuthMock.checkSignedIn).not.toHaveBeenCalled();
        expect(rejectedSpy).toHaveBeenCalledWith(undefined);
      });
    });

    describe("#signIn", function() {

      beforeEach(function() {
        spyOn(googleAuthMock, 'checkSignedIn');
      });

      function expectNoCallsToCheckSignedIn() {
        expect(googleAuthMock.checkSignedIn).not.toHaveBeenCalled();
      }

      it("should call #signIn on the chosen strategy", function() {

        spyOn(testAuthMock, 'signIn');
        spyOn(googleAuthMock, 'signIn').andReturn($q.when('foo'));

        var fulfilledSpy = jasmine.createSpy();
        service.signIn({ strategyName: 'google' }).then(fulfilledSpy);

        $rootScope.$apply();

        expectNoCallsToCheckSignedIn();
        expect(testAuthMock.signIn).not.toHaveBeenCalled();
        expect(googleAuthMock.signIn).toHaveBeenCalledWith(undefined);
        expect(fulfilledSpy).toHaveBeenCalledWith('foo');
      });

      it("should call #signIn with credentials on the chosen strategy", function() {

        spyOn(testAuthMock, 'signIn');
        spyOn(googleAuthMock, 'signIn').andReturn($q.when('foo'));

        var fulfilledSpy = jasmine.createSpy();
        service.signIn({ strategyName: 'google', credentials: 'bar' }).then(fulfilledSpy);

        $rootScope.$apply();

        expectNoCallsToCheckSignedIn();
        expect(testAuthMock.signIn).not.toHaveBeenCalled();
        expect(googleAuthMock.signIn).toHaveBeenCalledWith('bar');
        expect(fulfilledSpy).toHaveBeenCalledWith('foo');
      });

      it("should return a rejected promise if the process fails", function() {

        spyOn(testAuthMock, 'signIn');
        spyOn(googleAuthMock, 'signIn').andReturn($q.reject('baz'));

        var rejectedSpy = jasmine.createSpy();
        service.signIn({ strategyName: 'google', credentials: 'qux' }).then(undefined, rejectedSpy);

        $rootScope.$apply();

        expectNoCallsToCheckSignedIn();
        expect(testAuthMock.signIn).not.toHaveBeenCalled();
        expect(googleAuthMock.signIn).toHaveBeenCalledWith('qux');
        expect(rejectedSpy).toHaveBeenCalledWith('baz');
      });

      it("should return a rejected promise for an unknown strategy", function() {

        spyOn(testAuthMock, 'signIn');
        spyOn(googleAuthMock, 'signIn');

        var rejectedSpy = jasmine.createSpy();
        service.checkSignedIn({ strategyName: 'unknown' }).then(undefined, rejectedSpy);

        $rootScope.$apply();

        expectNoCallsToCheckSignedIn();
        expect(testAuthMock.signIn).not.toHaveBeenCalled();
        expect(googleAuthMock.signIn).not.toHaveBeenCalled();
        expect(rejectedSpy).toHaveBeenCalledWith(new Error('Unknown authentication strategy unknown'));
      });
    });
  });
});
