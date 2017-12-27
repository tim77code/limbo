# -*- coding: UTF-8 -*-
import os
import sys
import mock
import unittest
from mock import Mock

DIR = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, os.path.join(DIR, '../../limbo/plugins'))

from enable import on_message
from enable import init_plugins

class EnableTest(unittest.TestCase):

    @mock.patch('enable.init_plugins')
    def test_basic(self, init_plugins_mock):
        plugindir = 'test/plugindir'
        server = Mock()
        server.config = {'pluginpath': plugindir}
        ret = on_message({"text": u"!enable help,enable"}, server)
        assert ret == "enabling plugins: help,enable"
        init_plugins_mock.assert_called_with(plugindir, ['help','enable'])

    @mock.patch('enable.init_plugins')
    def test_star(self, init_plugins_mock):
        plugindir = 'test/plugindir'
        server = Mock()
        server.config = {'pluginpath': plugindir}
        ret = on_message({"text": u"!enable *"}, server)
        assert ret == "enabling all plugins"
        init_plugins_mock.assert_called_with(plugindir, None)
