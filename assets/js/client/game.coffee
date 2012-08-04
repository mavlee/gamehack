class window.Game extends Scene
  constructor: (@canvas, id, opponentId) ->
    super @canvas
    @player  = new Player id
    @opponent = new Player opponentId

    @init()


  init: ->
    @map = new GameObject @player.id
    @map.setSize @size.w+500, @size.h

    #bgSky = new Rect 0, 0, @size.w+500, @size.h-200, 'blue'
    #bgGround = new Rect 0, 150, @size.w+500, 200, 'green'
    bgSprite = new SpriteImage 'background.png'
    @map.addChild bgSprite

    @addBase @player.id
    @addBase @opponent.id

    if @player.id > @opponent.id
      @map.position.x = -@map.size.w + @canvas.width

    @onKeyDown 39, ( ->
      @scroll 6).bind this
    @onKeyDown 37, ( -> @scroll -6).bind this

    # UI
    @uiPanel = new Component 50, 5, @canvas.width-100, 50
    @uiPanel.addChild new Rect 0, 0, @uiPanel.size.w, @uiPanel.size.h, 'red'
    @spawnTank = new CooldownButton (new Rect 0, 0, 50, 50, 'green'), 5000
    @spawnTank.setPosition 5, 0
    @spawnTank.clickAction = (() ->
      socket.emit('add unit', {'playerId': @player.id, 'type': 'tank'})
    ).bind this
    @spawnSoldier = new CooldownButton (new Rect 0, 0, 50, 50, 'green'), 5000
    @spawnSoldier.setPosition 65, 0
    @spawnSoldier.clickAction = (() ->
      socket.emit('add unit', {'playerId': @player.id, 'type': 'soldier'})
    ).bind this
    @uiPanel.addChild @spawnTank
    @uiPanel.addChild @spawnSoldier

    @addChild @map
    @addChild @uiPanel

  addBase: (playerId) ->
    height = 210
    building = new Building playerId
    building.setSize 226, 100
    # fine for now, but maybe use a Player object later?
    if playerId == @player.id
      if @player.id < @opponent.id
        building.setPosition 0, height
      else
        building.setPosition @map.size.w-building.size.w, height
      @player.addBuilding building
    else
      if @player.id > @opponent.id
        building.setPosition 0, height
      else
        building.setPosition @map.size.w-building.size.w, height
      @opponent.addBuilding building
    @map.addChild building

  addUnit: (playerId, unitId, type) ->
    height = 270
    if type != "tank"
      height = 290
    if playerId == @player.id
      if @player.id < @opponent.id
        if type == 'tank'
          unit = new Tank(@player.id, 1.1, 'blue')
        else
          unit = new Soldier(@player.id, 1.1, 'blue')
        unit.setPosition 100, height
        unit.setDirection 1
      else
        if type == 'tank'
          unit = new Tank(@player.id, 1.1, 'red')
        else
          unit = new Soldier(@player.id, 1.1, 'red')
        unit.setPosition @map.size.w-135, height
        unit.setDirection -1
      @player.addUnit unit
    else
      if @player.id > @opponent.id
        if type == 'tank'
          unit = new Tank(@opponent.id, 1.1, 'blue')
        else
          unit = new Soldier(@opponent.id, 1.1, 'blue')
        unit.setPosition 100, height
        unit.setDirection 1
        @opponent.addUnit unit
      else
        if type == 'tank'
          unit = new Tank(@opponent.id, 1.1, 'red')
        else
          unit = new Soldier(@opponent.id, 1.1, 'red')
        unit.setPosition @map.size.w-135, height
        unit.setDirection -1
      @opponent.addUnit unit
    unit.addListener 'click', -> console.log 'click unit'
    @map.addChild unit


  update: (dt) ->
    if @player and @opponent
      for unit in @player.units
        for enemy in @opponent.units
          if unit.inRange enemy
            console.log 'inrange'
            unit.attack enemy
            break
        if unit.inRange @opponent.mainBase
          console.log 'attack base'
          console.log @opponent.mainBase.id
          unit.attack @opponent.mainBase
      for unit in @opponent.units
        for enemy in @player.units
          if unit.inRange enemy
            unit.attack enemy
            break
        if unit.inRange @player.mainBase
          console.log 'attack base2'
          unit.attack @player.mainBase

    super dt



  scroll: (dist) ->
    @map.position.x -= dist
    if @map.position.x > 0
      @map.position.x = 0
    else if @map.position.x < -@map.size.w + @canvas.width
      @map.position.x = -@map.size.w + @canvas.width
