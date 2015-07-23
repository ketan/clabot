'use strict'

_ = require 'lodash'

comment  = require './comment'
status   = require './status'
skip     = require './skip'

exports = module.exports = (req, res, options, contractors, payload) ->

  number = payload.number
  sender = payload.sender.login
  repo   = payload.repository.name
  user   = payload.repository.owner.login
  sha    = payload.pull_request.head.sha
  href   = payload.pull_request._links.html.href

  skip res, sender, options, contractors, { user, repo }, (contractors) ->
    signed = _.contains contractors, sender

    commentData      = { user, repo, number }
    commentData.body = comment.getCommentBody signed,
        options.templates,
        _.extend options.templateData, { sender, payload }

    success = true

    callback = _.after 2, ->
      if !success
        res.send 500, "Fatal Error: GitHub refused to comment or create status"
      else
        res.send 200, "Success: Comment and status created at #{href}"

    comment.send options.token, commentData, (err, data) ->
      if err
        success = false
        console.log err
        console.log   "Fatal Error: GitHub refused to comment"
      else
        href = payload.pull_request._links.html.href
        console.log   "Success: Comment created at #{href}"
      callback()

    statusData              = { user, repo, sha }
    statusData.state        =  if signed then 'success' else 'pending'
    statusData.description  =  if signed then 'CLA is signed' else 'CLA needs signing'
    statusData.context      = 'clabot'
    statusData.target_url   = options.templateData.link

    status.set options.token, statusData, (err, data) ->
      if err
        success = false
        console.log err
        console.log "Fatal Error: GitHub refused to create status"
      else
        console.log "Success: Status created at #{href}"
      callback()

