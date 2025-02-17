RootView = require 'views/core/RootView'
template = require 'app/templates/i18n/i18n-home-view'
CocoCollection = require 'collections/CocoCollection'
Courses = require 'collections/Courses'
Article = require 'models/Article'
utils = require 'core/utils'
if utils.isOzaria
  Interactive = require 'ozaria/site/models/Interactive'
  Cutscene = require 'ozaria/site/models/Cutscene'
ResourceHubResource = require 'models/ResourceHubResource'
ChatMessage = require 'models/ChatMessage'
AIScenario = require 'models/AIScenario'
AIDocument = require 'models/AIDocument'
AIChatMessage = require 'models/AIChatMessage'
Concept = require 'models/Concept'
StandardsCorrelation = require 'models/StandardsCorrelation'

LevelComponent = require 'models/LevelComponent'
ThangType = require 'models/ThangType'
Level = require 'models/Level'
Achievement = require 'models/Achievement'
Campaign = require 'models/Campaign'
if utils.isOzaria
  Cinematic = require 'ozaria/site/models/Cinematic'
Poll = require 'models/Poll'

languages = _.keys(require 'locale/locale').sort()
PAGE_SIZE = 100
QUERY_PARAMS = '?view=i18n-coverage&archived=false'

module.exports = class I18NHomeView extends RootView
  id: 'i18n-home-view'
  template: template

  events:
    'change #language-select': 'onLanguageSelectChanged'
    'change #type-select': 'onTypeSelectChanged'

  constructor: (options) ->
    super(options)
    @selectedLanguage = me.get('preferredLanguage') or ''
    @selectedTypes = ''

    #-
    i18nComparator =  (m) ->
      return 2 if m.specificallyCovered
      return 1 if m.generallyCovered
      return 0
    @aggregateModels = new Backbone.Collection()
    that = @
    filterModel = Backbone.Collection.extend({
      comparator: i18nComparator,
      filter: (attribute, value) ->
        @reset(that.aggregateModels.filter((model) ->
          return true if value is ''
          if attribute is 'className'
            return model.constructor.className is value
          else
            return model.get(attribute) is value
        ))
    })
    @filteredModels = new filterModel()
    @aggregateModels.comparator = i18nComparator

    project = ['name', 'components.original', 'i18n', 'i18nCoverage', 'slug']

    @thangTypes = new CocoCollection([], { url: "/db/thang.type#{QUERY_PARAMS}", project: project, model: ThangType })
    @components = new CocoCollection([], { url: "/db/level.component#{QUERY_PARAMS}", project: project, model: LevelComponent })
    @levels = new CocoCollection([], { url: "/db/level#{QUERY_PARAMS}", project: project, model: Level })
    @achievements = new CocoCollection([], { url: "/db/achievement#{QUERY_PARAMS}", project: project, model: Achievement })
    @campaigns = new CocoCollection([], { url: "/db/campaign#{QUERY_PARAMS}", project: project, model: Campaign })
    @polls = new CocoCollection([], { url: "/db/poll#{QUERY_PARAMS}", project: project, model: Poll })
    @courses = new Courses()
    @articles = new CocoCollection([], { url: "/db/article#{QUERY_PARAMS}", project: project, model: Article })
    @resourceHubResource = new CocoCollection([], { url: "/db/resource_hub_resource#{QUERY_PARAMS}", project: project, model: ResourceHubResource })
    if utils.isOzaria
      @interactive = new CocoCollection([], { url: "/db/interactive#{QUERY_PARAMS}", project: project, model: Interactive })
      @cinematics = new CocoCollection([], { url: "/db/cinematic#{QUERY_PARAMS}", project: project, model: Cinematic })
      @cutscene = new CocoCollection([], { url: "/db/cutscene#{QUERY_PARAMS}", project: project, model: Cutscene })
    @resourceHubResource = new CocoCollection([], { url: "/db/resource_hub_resource#{QUERY_PARAMS}", project: project, model: ResourceHubResource })
    @chatMessage = new CocoCollection([], { url: "/db/chat_message#{QUERY_PARAMS}", project: project, model: ChatMessage })
    @aiScenario = new CocoCollection([], { url: "/db/ai_scenario#{QUERY_PARAMS}", project: project, model: AIScenario })
    # @aiChatMessage = new CocoCollection([], { url: "/db/ai_chat_message#{QUERY_PARAMS}", project: project, model: AIChatMessage })
    # @aiDocument = new CocoCollection([], { url: "/db/ai_document#{QUERY_PARAMS}", project: project, model: AIDocument })
    @concepts = new CocoCollection([], { url: "/db/concept#{QUERY_PARAMS}", project: project, model: Concept })
    @standardsCorrelations = new CocoCollection([], { url: "/db/standards#{QUERY_PARAMS}", project: project, model: StandardsCorrelation })

    if utils.isOzaria
      collections = [@thangTypes, @components, @levels, @achievements, @campaigns, @polls, @courses, @articles, @interactive, @cinematics, @cutscene, @resourceHubResource, @concepts, @standardsCorrelations]
    else
      collections = [@thangTypes, @components, @levels, @achievements, @campaigns, @polls, @courses, @articles, @resourceHubResource, @chatMessage, @aiScenario, @concepts, @standardsCorrelations]
    for c in collections
      c.skip = 0

      c.fetch({data: {skip: 0, limit: PAGE_SIZE}, cache:false})
      @supermodel.loadCollection(c, 'documents')
      @listenTo c, 'sync', @onCollectionSynced


  onCollectionSynced: (collection) ->
    for model in collection.models
      model.i18nURLBase = switch model.constructor.className
        when 'Concept' then '/i18n/concept/'
        when 'StandardsCorrelation' then '/i18n/standards/'
        when 'ThangType' then '/i18n/thang/'
        when 'LevelComponent' then '/i18n/component/'
        when 'Achievement' then '/i18n/achievement/'
        when 'Level' then '/i18n/level/'
        when 'Campaign' then '/i18n/campaign/'
        when 'Poll' then '/i18n/poll/'
        when 'Course' then '/i18n/course/'
        when 'Product' then '/i18n/product/'
        when 'Article' then '/i18n/article/'
        when 'Interactive' then '/i18n/interactive/'
        when 'Cinematic' then '/i18n/cinematic/'
        when 'Cutscene' then '/i18n/cutscene/'
        when 'ResourceHubResource' then '/i18n/resource_hub_resource/'
        when 'ChatMessage' then '/i18n/chat_message/'
        when 'AIScenario' then '/i18n/ai/scenario/'
        when 'AIChatMessage' then '/i18n/ai/chat_message/'
        when 'AIDocument' then '/i18n/ai/document/'
    getMore = collection.models.length is PAGE_SIZE
    @aggregateModels.add(collection.models)
    @filteredModels.add(collection.models)
    @render()

    if getMore
      collection.skip += PAGE_SIZE
      collection.fetch({data: {skip: collection.skip, limit: PAGE_SIZE}})

  getRenderData: ->
    c = super()
    @updateCoverage()
    c.languages = languages
    c.selectedLanguage = @selectedLanguage
    c.selectedTypes = @selectedTypes
    c.collection = @filteredModels

    covered = (m for m in @filteredModels.models when m.specificallyCovered).length
    coveredGenerally = (m for m in @filteredModels.models when m.generallyCovered).length
    total = @filteredModels.models.length
    c.progress = if total then parseInt(100 * covered / total) else 100
    c.progressGeneral = if total then parseInt(100 * coveredGenerally / total) else 100
    c.showGeneralCoverage = /-/.test(@selectedLanguage ? 'en')  # Only relevant for languages with more than one family, like zh-HANS

    c

  updateCoverage: ->
    selectedBase = @selectedLanguage[..2]
    relatedLanguages = (l for l in languages when _.string.startsWith(l, selectedBase) and l isnt @selectedLanguage)
    for model in @filteredModels.models
      @updateCoverageForModel(model, relatedLanguages)
      model.generallyCovered = true if _.string.startsWith @selectedLanguage, 'en'
    @filteredModels.sort()

  updateCoverageForModel: (model, relatedLanguages) ->
    model.specificallyCovered = true
    model.generallyCovered = true
    coverage = model.get('i18nCoverage') ? []

    unless @selectedLanguage in coverage
      model.specificallyCovered = false
      if not _.any((l in coverage for l in relatedLanguages))
        model.generallyCovered = false
        return

  afterRender: ->
    super()
    @addLanguagesToSelect(@$el.find('#language-select'), @selectedLanguage)
    @$el.find('option[value="en-US"]').remove()
    @$el.find('option[value="en-GB"]').remove()
    if utils.isCodeCombat
      @addTypesToSelect($('#type-select'), ['ThangType', 'LevelComponent', 'Level', 'Achievement', 'Campaign', 'Poll', 'Course', 'Article', 'ResourceHubResource', 'ChatMessage', 'AIScenario'])
    else
      @addTypesToSelect($('#type-select'), ['ThangType', 'LevelComponent', 'Level', 'Achievement', 'Campaign', 'Poll', 'Course', 'Article', 'ResourceHubResource', 'Interactive', 'Cinematic', 'Cutscene'])

  onLanguageSelectChanged: (e) ->
    @selectedLanguage = $(e.target).val()
    if @selectedLanguage
      # simplest solution, see if this actually ends up being not what people want
      me.set('preferredLanguage', @selectedLanguage)
      me.patch()
    @render()

  addTypesToSelect: (e, types) ->
    $select = e
    $select.empty()
    $select.append($('<option>').attr('value', '').text('Select One...'))
    for type in types
      $select.append($('<option>').attr('value', type).text(type))

  onTypeSelectChanged: (e) ->
    @selectedType = $(e.target).val()
    @filteredModels.filter('className', @selectedType)
    @render()
    $('#type-select').val(@selectedType)