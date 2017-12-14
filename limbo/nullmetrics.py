class NullMetrics(object):
    def __init__(self, config={}):
        self.count = 0

    def events(self, count):
        self.count = self.count + count
