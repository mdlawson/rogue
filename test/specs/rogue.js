(function() {

  describe('Rogue', function() {
    return it('should exist on the global object', function() {
      return expect(window.Rogue).toBeDefined();
    });
  });

  describe('Game', function() {
    return it('can be created', function() {
      return expect(window.app.game).toBeDefined();
    });
  });

}).call(this);
