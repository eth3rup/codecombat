ContributeClassView = require './ContributeClassView'
template = require 'app/templates/contribute/adventurer'
{me} = require 'core/auth'

module.exports = class AdventurerView extends ContributeClassView
  id: 'adventurer-view'
  template: template

  initialize: ->
    @contributorClassName = 'adventurer'
