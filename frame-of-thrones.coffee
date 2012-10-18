Players = new Meteor.Collection("players")
Houses = new Meteor.Collection("houses")


if Meteor.isClient
  Template.players.players = ->
    players = Players.find({house:null}, {sort: {house: 1, name: 1}})

  Template.addplayer.new_player_name = ->
    Session.get("new_player_name")

  Template.mainframe.events
    'click input.add': -> 
      Players.insert
        name: $('#new-player').val(),
        house: null
      , ->
        setSortee()
        $('#new-player').val('')

    'keyup input#new-player': ->
      Session.set("new_player_name", $('#new-player').val());

  Template.player.events     
    'click span.remove': ->
      Players.remove
        _id: this._id

    
  Template.sorter.sortee = ->
    Session.get('sortee')

  Template.mainframe.houses = ->
    Houses.find()

  Template.house.players_objs = ->
    _.map(this.players || [], (player)->
      "player_name":player
    )


  Template.sorter.events
    'click input.random-unassigned-player': ->
      setSortee()

    'click input.assign-unassigned-player': ->
      assignSortee()

  Template.player.selected = ->
    Session.equals("selected_player", this._id) ? "selected" : '';
  
  setSortee = ->
    unassigned = $('.player.not-assigned')
    random = Math.floor Math.random()*unassigned.length
    random_player = unassigned.eq(random).find('.name').text()
    Session.set 'sortee', random_player;

  assignSortee = -> 
    # make sure we've got the correct round
    setRound()
    round = Session.get('round')

    # get the current round from the db
    sortee = Players.findOne name: Session.get('sortee')

    console.log round
    # get all the houses, there's only four after all
    # we only want ones with a player count less then the current round
    houses = Houses.find({playersCount: {$lt:round} }).map (doc)->
      doc
    
    # pick one
    random = Math.floor Math.random()*houses.length
    house = houses[random]
  
    # update the db
    # set the player against the house
    Houses.update {_id:house._id}, $addToSet: players:sortee.name
    # update the player count for the house
    # use the call back (third argument) to set the round
    newPlayerCount = Houses.findOne({_id:house._id}).players.length
    Houses.update {_id:house._id}, $set: playersCount: newPlayerCount, -> setRound()
    
    # set the house against the player
    # after it's finished set the sortee
    Players.update {_id:sortee._id}, $set: house: house.name, -> setSortee()


  setRound = ->
    maxPlayersCount = Houses.find({},{sort: {playersCount:1}, limit:1}).fetch()[0].playersCount
    Session.set('round',parseInt(maxPlayersCount)+1)

# On server startup, create some players if the database is empty.
if Meteor.isServer 
  Meteor.startup ->
    if Houses.find().count() == 0
      Houses.insert {name: house, playersCount: 0} for house in ['Lannister', 'Stark', 'Baratheon', 'Targaryen']
    if Players.find().count() == 0 
      Players.insert {name: player, house: null} for player in []

        