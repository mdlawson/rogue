describe 'Rogue', ->
	it 'should exist on the global object', ->
		expect(window.Rogue).toBeDefined()

describe 'Game', ->
	it 'can be created', ->
		expect(window.app.game).toBeDefined()
		