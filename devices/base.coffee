module.exports = (env) ->
  Promise = env.require 'bluebird'

  t = env.require('decl-api').types
  _ = env.require('lodash')
  assert = require 'cassert'
  Color = require 'color'


  class BaseLedLight extends env.devices.Device
    WHITE_MODE: 'WHITE'
    NIGHT_MODE: 'NIGHT'
    COLOR_MODE: 'COLOR'

    getTemplateName: -> 'led-light'

    attributes:
      power:
        description: 'the current state of the light'
        type: t.boolean
        labels: ['on', 'off']
      color:
        description: 'color of the light'
        type: t.string
        unit: 'hex color'
      mode:
        description: 'mode of the light'
        type: t.string
      brightness:
       description: 'brightness of the light'
       type: t.number
       unit: '%'

    template: 'led-light'

    actions:
      getPower:
        description: 'returns the current state of the light'
        returns:
          state:
            type: t.boolean
      getMode:
        description: 'returns the light mode'
      setMode:
        description: 'sets the light mode'
      turnOn:
        description: 'turns the light on'
      turnOff:
        description: 'turns the light off'
      toggle:
        description: 'turns the light off or off'
      setNight:
        description: 'set the light to night mode if supported'
      setWhite:
        description: 'set the light to white mode'
      setColor:
        description: 'set a light color'
        params:
          colorCode:
            type: t.string
      setBrightness:
        description: 'set the light brightness'
        params:
          brightnessValue:
            type: t.number
      changeDimlevelTo:
        description: "Sets the level of the dimmer"
        params:
          dimlevel:
            type: t.number

    constructor: (initState) ->
      unless @device
        throw new Error 'no device initialized'

      @name = @config.name
      @id = @config.id

      @power = initState?.power or false
      @color = initState?.color or ''
      @brightness = initState?.brightness or 100
      @mode = initState?.mode or @WHITE_MODE

      super()

    _setAttribute: (attributeName, value) ->
      unless @[attributeName] is value
        @[attributeName] = value
        @emit attributeName, value

    _setPower: (powerState) ->
      #console.log "POWER" , powerState
      unless @power is powerState
        @power = powerState
        @emit "power", if powerState then 'on' else 'off'

    _updateState: (err, state) ->
      env.logger.error err if err

      if state
        if state.mode is @WHITE_MODE or state.mode is @NIGHT_MODE
          @_setAttribute 'mode', state.mode
        else if state.mode is @COLOR_MODE
          @_setAttribute 'mode', @COLOR_MODE
          if state.color is ''
            @_setAttribute 'color', '#FFFFFF'
          else
            @_setAttribute 'color', Color(state.color).hexString()
        #console.log "hexColor:", hexColor
        @_setPower state.power
        @_setAttribute 'brightness', state.brightness
        
    getPower: -> Promise.resolve @power
    getColor: -> Promise.resolve @color
    getMode: -> Promise.resolve @mode
    getBrightness: -> Promise.resolve @brightness

    getState: ->
      mode: @mode
      color: if _.isString(@color) and not _.isEmpty(@color) then Color(@color).rgb() else ''
      power: @power
      brightness: @brightness

    turnOn: -> throw new Error "Function 'turnOn' is not implemented!"
    turnOff: -> throw new Error "Function 'turnOff' is not implemented!"
    setColor: -> throw new Error "Function 'setColor' is not implemented!"
    setNight: -> throw new Error "Function 'setNight' is not implemented!"
    setWhite: -> throw new Error "Function 'setWhite' is not implemented!"
    setMode: -> throw new Error "Function 'setMode' is not implemented!"
    setBrightness: (brightnessValue) -> throw new Error "Function 'setBrightness' is not implemented!"
    changeDimlevelTo: (dimLevel) -> @setBrightness(dimLevel)  

    toggle: ->
      if @power is 'on' then @turnOn() else @turnOff()
      Promise.resolve()

  return BaseLedLight
