# -*- coding: UTF-8 -*-
import os
import sys

import limbo

def test_event_count():
    msg = u"!echo Iñtërnâtiônàlizætiøn bot"
    oldmsg = u"old message"
    newmsg = u"!echo new message"
    events = [[
        { "channel" : "none", "user": "2", "text": msg},
        { "channel" : "none", "user": "2", "type": "message", "subtype": "channel_join",
          "text": "User has joined" },
        { "channel" : "none", "user": "2", "type": "member_left_channel" },
        { "channel" : "none", "type": "message", "subtype": "message_changed",
          "previous_message": {"text": oldmsg},
          "message": {"text": newmsg, "user": "msguser"} }
    ]]
    slack = limbo.FakeSlack(events=events)

    hooks = limbo.init_plugins("test/plugins")
    server = limbo.FakeServer(hooks=hooks, slack=slack)

    metrics = limbo.NullMetrics()

    limbo.loop(server, metrics, test_loop=1)

    assert metrics.count == 4
