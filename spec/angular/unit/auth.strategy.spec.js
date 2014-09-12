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
    });
  });
});
